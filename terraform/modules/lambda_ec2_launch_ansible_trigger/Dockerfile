FROM public.ecr.aws/lambda/python:3.9

WORKDIR /var/task

# boto3とparamikoを/var/taskにインストール
RUN pip install --target /var/task boto3 paramiko

# デフォルトエントリポイントを/bin/bashに変更
ENTRYPOINT ["/bin/bash"]