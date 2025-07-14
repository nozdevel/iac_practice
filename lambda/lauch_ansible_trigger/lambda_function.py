import boto3
import paramiko
import os
import stat
import logging
import platform
import sys
import subprocess

ssm = boto3.client('ssm')
secretsmanager = boto3.client('secretsmanager')
ec2 = boto3.client('ec2')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def print_env_info():
    logger.info("OS: %s", platform.platform())
    logger.info("Python: %s", sys.version)
    logger.info("Libc: %s", subprocess.getoutput('ldd --version'))
    logger.info("uname: %s", os.uname())

def lambda_handler(event, context):
    print_env_info()
    logger.info(f"Received event: {event}")
    ssh = None
    try:
        # 新規EC2インスタンスIDをイベントから取得
        instance_id = event.get('instance_id')
        if not instance_id:
            raise ValueError("instance_id not found in event payload")
        logger.info(f"Instance ID: {instance_id}")

        # 新規EC2のプライベートIPを取得
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        logger.info(f"describe_instances response: {resp}")
        instance = resp['Reservations'][0]['Instances'][0]
        new_ec2_ip = instance['PrivateIpAddress']
        logger.info(f"New EC2 IP: {new_ec2_ip}")

        # BastionのIP取得（タグ名で検索）
        environment = os.environ['ENV']
        filters = [
            {'Name': 'tag:Name', 'Values': [f'{environment}-bastion-ansible']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
        logger.info(f"Bastion search filters: {filters}")
        resp = ec2.describe_instances(Filters=filters)
        logger.info(f"Bastion describe_instances response: {resp}")
        reservations = resp.get('Reservations', [])
        if not reservations or not reservations[0]['Instances']:
            logger.error("No running bastion_ansible instance found.")
            return {'statusCode': 500, 'body': 'No running bastion_ansible instance found.'}
        bastion_instance = reservations[0]['Instances'][0]
        bastion_host = bastion_instance.get('PrivateIpAddress')
        if not bastion_host:
            logger.error("Bastion instance has no private IP.")
            return {'statusCode': 500, 'body': 'Bastion instance has no private IP.'}
        logger.info(f"Bastion Host (Private IP): {bastion_host}")

        # Secrets Managerから秘密鍵取得
        logger.info("Getting private key from Secrets Manager.")
        secret_response = secretsmanager.get_secret_value(SecretId=os.environ['BASTION_SSH_KEY_SECRET'])
        logger.info(f"Secret response: {secret_response}")
        private_key_str = secret_response['SecretString']

        bastion_user = os.environ['BASTION_USER']
        logger.info(f"Bastion user: {bastion_user}")

        # /tmpに秘密鍵を書き込み
        key_path = '/tmp/temp_key.pem'
        logger.info(f"Writing private key to {key_path}")
        with open(key_path, 'w') as f:
            f.write(private_key_str)
        os.chmod(key_path, stat.S_IRUSR | stat.S_IWUSR)  # chmod 600
        logger.info("Private key file permissions set to 600.")

        # SSH接続（リトライ処理付き）
        import time
        import traceback
        logger.info(f"Starting SSH connection to bastion. host={bastion_host}, user={bastion_user}, key_path={key_path}")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        connected = False
        for i in range(5):
            try:
                ssh.connect(hostname=bastion_host, username=bastion_user, key_filename=key_path, timeout=30)
                logger.info(f"SSH connection established (try {i+1}/5)")
                # banner情報も出力
                try:
                    banner = ssh.get_transport().remote_version if ssh.get_transport() else None
                    logger.info(f"SSH remote banner: {banner}")
                except Exception as banner_err:
                    logger.warning(f"Could not get SSH banner: {banner_err}")
                connected = True
                break
            except Exception as e:
                logger.warning(f"SSH connect failed (try {i+1}/5): {e}")
                logger.warning(f"Exception type: {type(e).__name__}, args: {e.args}")
                logger.warning(f"Traceback: {traceback.format_exc()}")
                time.sleep(10)
        if not connected:
            logger.error("SSH connection failed after 5 retries.")
            logger.error(f"host={bastion_host}, user={bastion_user}, key_path={key_path}")
            if ssh:
                try:
                    ssh.close()
                except Exception as close_err:
                    logger.warning(f"Error closing SSH after failure: {close_err}")
            return {
                'statusCode': 500,
                'body': f'SSH connection failed after retries: {bastion_host}'
            }

        # Ansibleを再実行
        ansible_cmd = "cd /home/ec2-user/ansible && ./run_with_reload_hosts.sh"
        logger.info(f"Executing Ansible command: {ansible_cmd}")
        stdin, stdout, stderr = ssh.exec_command(ansible_cmd)
        out = stdout.read().decode()
        err = stderr.read().decode()

        logger.info(f"Ansible STDOUT: {out}")
        logger.info(f"Ansible STDERR: {err}")

        # SSH接続後、ディレクトリとファイルの存在確認
        for cmd in [
            "ls -l /home/ec2-user/ansible",
            "pwd",
            "whoami"
        ]:
            logger.info(f"Executing: {cmd}")
            stdin, stdout, stderr = ssh.exec_command(cmd)
            out = stdout.read().decode()
            err = stderr.read().decode()
            logger.info(f"{cmd} STDOUT: {out}")
            logger.info(f"{cmd} STDERR: {err}")

        # SSH接続は必ずクローズする
        try:
            if ssh:
                ssh.close()
                logger.info("SSH connection closed.")
        except Exception as close_err:
            logger.warning(f"Error closing SSH: {close_err}")

        return {
            'statusCode': 200,
            'body': f'Ansible executed successfully.\nSTDOUT:\n{out}\nSTDERR:\n{err}'
        }

    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        # 例外発生時も必ずSSHクローズ
        try:
            if ssh:
                ssh.close()
                logger.info("SSH connection closed (on exception).")
        except Exception as close_err:
            logger.warning(f"Error closing SSH (on exception): {close_err}")
        return {
            'statusCode': 500,
            'body': f'Error executing Ansible: {str(e)}'
        }
