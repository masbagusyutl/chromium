#!/bin/bash

# Fungsi untuk menampilkan logo & informasi awal
print_welcome_message() {
    echo -e "\033[1;37m"
    echo " _  _ _   _ ____ ____ _    ____ _ ____ ___  ____ ____ ___ "
    echo "|\\ |  \\_/  |__| |__/ |    |__| | |__/ |  \\ |__/ |  | |__]"
    echo "| \\|   |   |  | |  \\ |    |  | | |  \\ |__/ |  \\ |__| |    "
    echo -e "\033[1;32m"
    echo "Nyari Airdrop Auto install Chromium"
    echo -e "\033[1;33m"
    echo "Telegram: https://t.me/nyariairdrop"
    echo -e "\033[0m"
}

# Fungsi untuk memeriksa apakah perangkat bisa menjalankan Chromium
check_system_requirements() {
    echo "🔍 Memeriksa spesifikasi perangkat..."
    CPU_MODEL=$(lscpu | grep "Model name" | awk -F ':' '{print $2}')
    TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
    FREE_DISK=$(df -h / | awk 'NR==2 {print $4}')
    OS_VERSION=$(lsb_release -d | awk -F ':' '{print $2}')

    echo "🖥️ CPU: $CPU_MODEL"
    echo "💾 RAM: ${TOTAL_RAM}MB"
    echo "🗄️  Free Disk: $FREE_DISK"
    echo "📀 OS: $OS_VERSION"

    if [[ "$TOTAL_RAM" -lt 2000 ]]; then
        echo "⚠️ RAM kurang dari 2GB! Instalasi Chromium mungkin tidak berjalan dengan lancar."
        read -p "Lanjutkan instalasi? (y/n): " choice
        if [[ "$choice" != "y" ]]; then
            echo "🚫 Instalasi dibatalkan."
            exit 1
        fi
    fi
}

# Fungsi untuk memeriksa apakah skrip dijalankan sebagai root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ Skrip ini harus dijalankan sebagai root. Keluar..."
        exit 1
    fi
}

# Fungsi untuk menginstal Docker
install_docker() {
    echo "⚙️  Menginstal Docker..."
    sudo apt update -y && sudo apt upgrade -y || { echo "❌ Gagal memperbarui paket. Keluar..."; exit 1; }

    # Hapus paket yang konflik
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || echo "⚠️ Gagal menghapus $pkg, mungkin tidak terinstal."
    done

    # Instal dependensi yang diperlukan
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || { echo "❌ Gagal menginstal dependensi. Keluar..."; exit 1; }

    # Tambahkan kunci GPG resmi Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || { echo "❌ Gagal menambahkan kunci GPG Docker. Keluar..."; exit 1; }

    # Siapkan repositori stabil Docker
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || { echo "❌ Gagal menambahkan repositori Docker. Keluar..."; exit 1; }

    # Instal Docker
    sudo apt update -y && sudo apt install -y docker-ce || { echo "❌ Gagal menginstal Docker. Keluar..."; exit 1; }

    # Mulai dan aktifkan layanan Docker
    sudo systemctl start docker || { echo "❌ Gagal memulai layanan Docker. Keluar..."; exit 1; }
    sudo systemctl enable docker || { echo "❌ Gagal mengaktifkan layanan Docker. Keluar..."; exit 1; }

    echo "✅ Docker berhasil diinstal."
}

# Fungsi untuk menginstal Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "⚙️  Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { echo "❌ Gagal mengunduh Docker Compose. Keluar..."; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose
        echo "✅ Docker Compose berhasil diinstal."
    else
        echo "✅ Docker Compose sudah terinstal."
    fi
}

# Fungsi untuk mendapatkan zona waktu server
get_timezone() {
    TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
    if [ -z "$TIMEZONE" ]; then
        read -p "Masukkan zona waktu Anda (default: Asia/Jakarta): " user_timezone
        TIMEZONE=${user_timezone:-Asia/Jakarta}
    fi
    echo "🕒 Zona waktu server: $TIMEZONE"
}

# Fungsi untuk menghasilkan kata yang bisa diucapkan
generate_pronounceable_word() {
    VOWELS=("a" "i" "u" "e" "o")
    CONSONANTS=("b" "c" "d" "f" "g" "h" "j" "k" "l" "m" "n" "p" "r" "s" "t" "v" "w" "y" "z")

    WORD=""
    for i in {1..2}; do
        WORD+="${CONSONANTS[$RANDOM % ${#CONSONANTS[@]}]}"
        WORD+="${VOWELS[$RANDOM % ${#VOWELS[@]}]}"
    done

    echo "$WORD"
}

# Fungsi untuk menghasilkan nama pengguna unik
generate_username() {
    BASE=$(generate_pronounceable_word)
    NUM=$((RANDOM % 100 + 10))
    echo "$BASE$NUM"
}

# Fungsi untuk menghasilkan kata sandi yang mudah diingat tetapi tetap aman
generate_password() {
    WORD1=$(generate_pronounceable_word)
    WORD2=$(generate_pronounceable_word)
    SPECIAL_CHARS=("!" "@" "#" "$" "%" "&")
    CHAR=${SPECIAL_CHARS[$RANDOM % ${#SPECIAL_CHARS[@]}]}
    NUM=$((RANDOM % 90 + 10))

    echo "$WORD1$WORD2$CHAR$NUM"
}

# Menampilkan logo & informasi awal
print_welcome_message

# Periksa apakah skrip dijalankan sebagai root
check_root

# Periksa apakah perangkat bisa menjalankan Chromium
check_system_requirements

# Periksa dan instal Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "✅ Docker sudah terinstal."
fi

# Periksa dan instal Docker Compose
install_docker_compose

# Dapatkan zona waktu server
get_timezone

# Hasilkan nama pengguna dan kata sandi
CUSTOM_USER=$(generate_username)
PASSWORD=$(generate_password)

# Siapkan Chromium dengan Docker Compose
echo "🚀 Menyiapkan Chromium dengan Docker Compose..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Verifikasi apakah docker-compose.yaml berhasil dibuat
if [ ! -f "docker-compose.yaml" ]; then
    echo "❌ Gagal membuat docker-compose.yaml. Keluar..."
    exit 1
fi

# Jalankan kontainer Chromium
echo "🔄 Menjalankan kontainer Chromium..."
docker-compose up -d || { echo "❌ Gagal menjalankan kontainer Docker. Keluar..."; exit 1; }

# Dapatkan alamat IP VPS
IPVPS=$(curl -s ifconfig.me)

# Output informasi akses
echo "🔗 Kredensial akses Chromium di browser Anda:"
echo "   👉 http://$IPVPS:3010/ atau https://$IPVPS:3011/"
echo "   🆔 Nama pengguna: $CUSTOM_USER"
echo "   🔑 Kata sandi: $PASSWORD"
echo "   ⚠️ Harap simpan data Anda!"

# Bersihkan sumber daya Docker yang tidak terpakai
docker system prune -f
echo "🧹 Sistem Docker telah dibersihkan."

# Kesimpulan Proses
echo -e "\n🎉 **Instalasi Selesai!** 🎉"
echo "✅ Chromium telah berhasil diinstal dan berjalan di server Anda."
echo "🔹 Gunakan kredensial yang diberikan untuk login."
echo "🔹 Jangan lupa bergabung ke : https://t.me/nyariairdrop"
echo "🚀 Selamat mencoba! 🚀"
