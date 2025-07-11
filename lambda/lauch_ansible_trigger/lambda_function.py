import boto3
import paramiko
import os
import stat

ssm = boto3.client('ssm')
secretsmanager = boto3.client('secretsmanager')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    try:
        # 新規EC2インスタンスIDをイベントから取得
        instance_id = event['detail']['instance-id']

        # 新規EC2のプライベートIPを取得
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        instance = resp['Reservations'][0]['Instances'][0]
        new_ec2_ip = instance['PrivateIpAddress']

        # BastionのIP取得（タグ名で検索）
        filters = [
            {'Name': 'tag:Name', 'Values': ['bastion_ansible']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
        resp = ec2.describe_instances(Filters=filters)
        reservations = resp.get('Reservations', [])
        if not reservations or not reservations[0]['Instances']:
            return {'statusCode': 500, 'body': 'No running bastion_ansible instance found.'}
        bastion_instance = reservations[0]['Instances'][0]
        bastion_host = bastion_instance.get('PublicIpAddress') or bastion_instance.get('PrivateIpAddress')
        if not bastion_host:
            return {'statusCode': 500, 'body': 'Bastion instance has no reachable IP.'}

        # Secrets Managerから秘密鍵取得
        secret_response = secretsmanager.get_secret_value(SecretId=os.environ['BASTION_SSH_KEY_SECRET'])
        private_key_str = secret_response['SecretString']

        bastion_user = os.environ['BASTION_USER']

        # /tmpに秘密鍵を書き込み
        key_path = '/tmp/temp_key.pem'
        with open(key_path, 'w') as f:
            f.write(private_key_str)
        os.chmod(key_path, stat.S_IRUSR | stat.S_IWUSR)  # chmod 600

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname=bastion_host, username=bastion_user, key_filename=key_path)

        # 新EC2のIPをインベントリに追加
        inventory_path = '/home/ec2-user/iac_practice/ansible/inventory/hosts'
        add_host_cmd = f"echo '{new_ec2_ip}' >> {inventory_path}"
        ssh.exec_command(add_host_cmd)

        # Ansibleを再実行
        ansible_cmd = "cd /home/ec2-user/iac_practice/ansible && ./run_with_reload_hosts.sh"
        stdin, stdout, stderr = ssh.exec_command(ansible_cmd)
        out = stdout.read().decode()
        err = stderr.read().decode()

        ssh.close()

        return {
            'statusCode': 200,
            'body': f'Ansible executed successfully.\nSTDOUT:\n{out}\nSTDERR:\n{err}'
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error executing Ansible: {str(e)}'
        }
