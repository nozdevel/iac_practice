import boto3
import paramiko
import os
import stat

ssm = boto3.client('ssm')
secretsmanager = boto3.client('secretsmanager')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    try:
        # bastionのタグ名 or セキュリティグループで動的にIPを取得
        filters = [
            {'Name': 'tag:Name', 'Values': ['bastion_ansible']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
        resp = ec2.describe_instances(Filters=filters)
        reservations = resp.get('Reservations', [])
        if not reservations or not reservations[0]['Instances']:
            return {'statusCode': 500, 'body': 'No running bastion_ansible instance found.'}

        instance = reservations[0]['Instances'][0]
        bastion_host = instance.get('PublicIpAddress') or instance.get('PrivateIpAddress')
        if not bastion_host:
            return {'statusCode': 500, 'body': 'Bastion instance has no reachable IP.'}

        # Secrets Managerから秘密鍵取得
        secret_response = secretsmanager.get_secret_value(SecretId=os.environ['BASTION_SSH_KEY_SECRET'])
        private_key_str = secret_response['SecretString']

        bastion_user = os.environ['BASTION_USER']
        ansible_command = os.environ['ANSIBLE_COMMAND']

        # /tmpに秘密鍵を書き込み
        key_path = '/tmp/temp_key.pem'
        with open(key_path, 'w') as f:
            f.write(private_key_str)
        os.chmod(key_path, stat.S_IRUSR | stat.S_IWUSR)  # chmod 600

        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        ssh.connect(hostname=bastion_host, username=bastion_user, key_filename=key_path)

        stdin, stdout, stderr = ssh.exec_command(ansible_command)
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
