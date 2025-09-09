exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "--- Iniciando script user-data com Docker e EFS ---"

yum update -y
yum install -y docker amazon-efs-utils

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

EFS_MOUNT_POINT="/mnt/efs"
mkdir -p $EFS_MOUNT_POINT

echo "${efs_dns_name}:/ $EFS_MOUNT_POINT efs _netdev,tls 0 0" >> /etc/fstab

mount -a -t efs

if ! grep -qs "$EFS_MOUNT_POINT" /proc/mounts; then
    echo "ERRO CRÍTICO: Falha ao montar o EFS em $EFS_MOUNT_POINT."
    exit 1
fi
echo "EFS montado com sucesso em $EFS_MOUNT_POINT"

mkdir -p $EFS_MOUNT_POINT/wordpress_data

chown -R 33:33 $EFS_MOUNT_POINT/wordpress_data

COMPOSE_FILE_PATH="$EFS_MOUNT_POINT/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE_PATH" ]; then
  echo "docker-compose.yml não encontrado. Criando..."
  cat <<EOF > $COMPOSE_FILE_PATH
version: '3.7'
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: "${db_host}"
      WORDPRESS_DB_USER: "${db_user}"
      WORDPRESS_DB_PASSWORD: "${db_password}"
      WORDPRESS_DB_NAME: "${db_name}"
    volumes:
      - ./wordpress_data:/var/www/html
EOF
  echo "Arquivo docker-compose.yml criado."
else
  echo "Arquivo docker-compose.yml já existe."
fi

cd $EFS_MOUNT_POINT
docker-compose up -d

echo "--- Script user-data finalizado ---"