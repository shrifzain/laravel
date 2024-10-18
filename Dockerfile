name: Deploy Laravel Application

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    # Checkout the code
    - name: Checkout code
      uses: actions/checkout@v2

    # Set up Docker Buildx
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    # Log in to DockerHub or another registry
    - name: Log in to DockerHub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    # Build the Docker image
    - name: Build Docker image
      run: |
        docker build -t my-laravel-app .

    # Run Laravel migrations
    - name: Run migrations
      run: |
        docker run --env-file .env -v $(pwd):/var/www/html my-laravel-app php artisan migrate --force
      env:
        APP_KEY: ${{ secrets.APP_KEY }}
        MYSQL_HOST: ${{ secrets.MYSQL_HOST }}
        MYSQL_DATABASE: ${{ secrets.MYSQL_DATABASE }}
        MYSQL_USER: ${{ secrets.MYSQL_USER }}
        MYSQL_PASSWORD: ${{ secrets.MYSQL_PASSWORD }}

    # Tag and push the Docker image to DockerHub
    - name: Tag Docker image
      run: |
        docker tag my-laravel-app:latest ${{ secrets.DOCKER_USERNAME }}/my-laravel-app:latest

    - name: Push Docker image to DockerHub
      run: |
        docker push ${{ secrets.DOCKER_USERNAME }}/my-laravel-app:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
    # SSH into EC2 instance and deploy the Docker container
    - name: Deploy to EC2
      uses: appleboy/ssh-action@v0.1.3
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ${{ secrets.EC2_USER }}
        key: ${{ secrets.EC2_SSH_KEY }}
        script: |
          docker pull ${{ secrets.DOCKER_USERNAME }}/my-laravel-app:latest
          docker stop my-laravel-app || true
          docker rm my-laravel-app || true
          docker run -d -p 80:80 --name my-laravel-app --env-file /path/to/.env ${{ secrets.DOCKER_USERNAME }}/my-laravel-app:latest
