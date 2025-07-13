FROM public.ecr.aws/lambda/python:3.9

WORKDIR /var/task

# 依存パッケージをインストール
RUN pip install boto3 paramiko -t /var/task

# デフォルトエントリポイントを/bin/bashに変更
ENTRYPOINT ["/bin/bash"]