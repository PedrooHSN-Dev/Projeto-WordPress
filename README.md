# WordPress de Alta Disponibilidade na AWS com Terraform e Docker
## ✅ Pré-requisitos

Antes de começar, certifique-se de ter o seguinte instalado e configurado:

  * **Terraform**
  * **Credenciais da AWS**: Configure suas próprias credênciais AWS pelo meio que preferir, seja pelo AWS CLI ou variáveis de ambiente.

## 📖 Resumo do Projeto

Este projeto utiliza o Terraform para provisionar uma infraestrutura completa, escalável e de alta disponibilidade para uma aplicação WordPress na AWS. A aplicação é executada em contêineres gerenciados por Docker e Docker Compose nas instâncias EC2 criadas pelo load balancer.

## 🏗️ Arquitetura da Solução

  * **VPC**: Uma VPC distribuída em duas Zonas de Disponibilidade.
  * **Sub-redes**:
      * **Públicas**: Hospedam o Application Load Balancer (ALB), que serve como ponto de entrada para o tráfego web.
      * **Privadas**: Hospedam as instâncias EC2, o banco de dados RDS e os mount targets do EFS, protegendo-os do acesso direto.
  * **Fluxo de Tráfego**: O usuário acessa o site através do DNS do ALB. O ALB distribui o tráfego HTTP (porta 80) para as instâncias EC2 dentro de um Auto Scaling Group.
  * **Aplicação**: As instâncias EC2 executam um contêiner Docker com a imagem oficial do WordPress. O `docker-compose` é utilizado para orquestrar o contêiner.
  * **Persistência de Dados**:
      * **Amazon RDS (MySQL)**: Um banco de dados gerenciado armazena posts, usuários e configurações do site.
      * **Amazon EFS**: Um sistema de arquivos compartilhado armazena todos os arquivos do WordPress (`/var/www/html`), incluindo uploads, temas e plugins, garantindo que todas as instâncias compartilhem os mesmos dados.


## 📂 Estrutura dos Arquivos

```
main.tf                 # Define o provedor AWS
variables.tf            # Declara todas as variáveis utilizadas
terraform.tfvars        # Arquivo principal para definir suas variáveis
vpc.tf                  # Cria a VPC, sub-redes, gateways e tabelas de rota
security_groups.tf      # Define as regras de firewall (ALB, EC2, RDS, EFS)
iam.tf                  # Cria a IAM Role para gerenciamento via AWS SSM
rds.tf                  # Provisiona o banco de dados MySQL no Amazon RDS
efs.tf                  # Provisiona o sistema de arquivos compartilhado Amazon EFS
alb.tf                  # Cria o Application Load Balancer, Target Group e Listener
asg.tf                  # Define o Launch Template e o Auto Scaling Group
user-data.sh     # Script de inicialização (instala Docker, monta EFS, etc.)
outputs.tf              # Define as saídas do projeto (DNS do Load Balancer para facilitar)
```

## ⚙️ Como Configurar

A única configuração necessária é no arquivo `terraform.tfvars`. Crie este arquivo e preencha as variáveis com os seus valores desejados.

Exemplo de `terraform.tfvars`:

```terraform
# Credenciais para o banco de dados RDS
db_username = "xxxxxxxx"
db_password = "xxxxxxxx"
```

## 🚀 Como Implantar (Deploy)

Com os pré-requisitos instalados e a configuração feita, execute os seguintes comandos no terminal, dentro do diretório do projeto:

1.  **Inicializar o Terraform:**
    Este comando baixa os plugins necessários para interagir com a AWS.

    ```bash
    terraform init
    ```

2.  **Planejar a Execução:**
    O Terraform irá mostrar todos os recursos que serão criados. É uma boa prática revisar o plano antes de aplicar.

    ```bash
    terraform plan
    ```

3.  **Aplicar a Configuração:**
    Este comando irá criar toda a infraestrutura na sua conta AWS. A execução pode levar vários minutos.

    ```bash
    terraform apply
    ```

    O Terraform pedirá uma confirmação. Digite `yes` e pressione **Enter**.

Após a conclusão, o Terraform exibirá o DNS do seu site na seção `Outputs`.

## 🔬 Verificação e Testes

Após o deploy, é crucial verificar se os principais componentes de alta disponibilidade estão funcionando.

### Testando o EFS

Este teste garante que os arquivos (como imagens de mídia) são persistidos e compartilhados entre as instâncias.

1.  Acesse o site usando o DNS do ALB e complete a instalação do WordPress.
2.  No painel de admin, vá em **Mídia \> Adicionar nova** e faça o upload de uma imagem.
3.  Vá ao **Console da AWS \> EC2 \> Auto Scaling Groups**, selecione o grupo do projeto e termine uma das instâncias.
4.  Aguarde o ASG lançar uma nova instância.
5.  Recarregue o site. A imagem que você subiu deve continuar visível, provando que ela foi salva no EFS e não no disco local da instância terminada.

### Testando o Load Balancer

Este teste garante que o ALB está redirecionando o tráfego corretamente em caso de falha.

1.  Acesse **EC2 \> Target Groups**, selecione o grupo do projeto e veja que ambas as instâncias estão com o status `healthy`.
2.  Conecte-se a uma das instâncias via **Session Manager**.
3.  Pare o serviço do WordPress com o comando:
    ```bash
    cd /mnt/efs
    sudo docker-compose down
    ```
4.  No console do Target Group, observe o status da instância mudar para `unhealthy` após alguns instantes.
5.  Recarregue seu site no navegador. Ele deve continuar funcionando normalmente, pois o ALB redirecionou todo o tráfego para a instância saudável.
6.  Para restaurar, execute `sudo docker-compose up -d` na instância.

## 💣 Destruindo a Infraestrutura

Execute o seguinte comando e confirme digitando `yes`:

```bash
terraform destroy
```
