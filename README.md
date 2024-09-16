# Documentação de Configuração - AWS e Linux

**Autor:** Thiago Barbosa

## Parte 1: Requisitos AWS

### 1. Criar VPC e Conexões Necessárias
1. Acesse o console da AWS e vá até a seção **VPC**.
2. Clique em **Create VPC** e insira as seguintes informações:
   - **Name tag:** `my-vpc`
   - **IPv4 CIDR block:** `10.0.0.0/24`
   - **Tenancy:** Default
3. Crie uma **subnet**:
   - Vá até **Subnets** e clique em **Create Subnet**.
   - **Name tag:** `my-subnet`
   - **CIDR block:** `10.0.0.0/28`
4. Crie um **Internet Gateway**:
   - Vá até **Internet Gateway** e clique em **Create Internet Gateway**.
   - Anexe o Internet Gateway à VPC.
5. Atualize a **Route Table** para rotear o tráfego da subnet para o Internet Gateway:
   - Destino: `0.0.0.0/0`
   - Target: `my-internet-gateway` criada

### 2. Gerar Chave Pública
1. No console da AWS, vá até **EC2** > **Key Pairs**.
2. Clique em **Create Key Pair**.
3. Nomeie a chave (ex: `my-key`) e faça o download do arquivo `.pem`.

### 3. Criar Instância EC2
1. No console da AWS, vá até **EC2** e clique em **Launch Instance**.
2. Em **Name and tags** configure 3 valores
   - `Name` / `PB - JUL 2024` / `Instances e Volumes`
   - `CostCenter` / `C092000024` / `Instances e Volumes`
   - `Project`/  `PB - JUL 2024` / `Instances e Volumes`
3. Escolha a AMI **Amazon Linux 2**.
4. Selecione o tipo de instância como **t3.small**.
5. Selecione a chave pública criada para conexão a instância
6. Configure o armazenamento como **16 GB SSD**.
7. Em **Network Settings** registre as seguintes regras _(é possível ser editado posteriormente em **Security Group**)_:
   - Porta 22/TCP (SSH) - source type `Anywhere`
   - Porta 80/TCP (HTTP) - source type `Anywhere`
   - Porta 443/TCP (HTTPS) - source type `Anywhere`
   - Porta 111/TCP e UDP (NFS) - source type `Anywhere`
   - Porta 2049/TCP e UDP (NFS) - source type `Anywhere`
8. Gere um **Elastic IP** e anexe à instância EC2.

---

## Parte 2: Requisitos no Linux

### 1. Configurar NFS
1. Conecte-se à instância EC2 via SSH:
   ```bash
   ssh -i "minha-chave.pem" ec2-user@<Elastic-IP>
   ```
2. Instale o servidor NFS:
   ```bash
   sudo yum install nfs-utils -y
   sudo mkdir /mnt/nfs_share
   sudo chown -R ec2-user:ec2-user /mnt/nfs_share
   sudo echo "/mnt/nfs_share *(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
   sudo systemctl start nfs-server
   sudo systemctl enable nfs-server
   ```
3. Crie um diretório no NFS com o seu nome:
   ```bash
   mkdir /mnt/nfs_share/thiagobarbosa
   ```

### 2. Subir Apache no Servidor
1. Instale o Apache:
   ```bash
   sudo yum install httpd -y
   sudo systemctl start httpd
   sudo systemctl enable httpd
   ```

### 3. Criar Script de Monitoramento
1. Crie o script Bash para verificar o status do Apache:
   ```bash
   sudo nano monitor_apache.sh
   ```
2. Adicione o seguinte conteúdo:
   ```bash
   #!/bin/bash
   SERVICE="httpd"
   STATUS=$(systemctl is-active $SERVICE)
   DATE=$(date '+%Y-%m-%d %H:%M:%S')
   DIR="/mnt/nfs_share/thiagobarbosa"
   
   if [ "$STATUS" = "active" ]; then
     echo "$DATE - $SERVICE - ONLINE - Serviço está funcionando" > $DIR/apache_online.txt
   else
     echo "$DATE - $SERVICE - OFFLINE - Serviço está fora do ar" > $DIR/apache_offline.txt
   fi
   ```
3. Torne o script executável:
   ```bash
   sudo chmod +x /usr/local/bin/monitor_apache.sh
   ```

### 4. Automatizar o Script com Cron
1. Configure o cron para executar o script a cada 5 minutos:
   ```bash
   crontab -e
   ```
2. Adicione a seguinte linha:
   ```bash
   */5 * * * * /usr/local/bin/monitor_apache.sh
   ```
