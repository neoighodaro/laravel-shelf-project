# Laravel Shelf Project

This is a template for a Laravel project. You can use it to create a new Laravel project. It is useful if you don't have PHP or composer installed on your machine and you still want to use Laravel.

The project contains a Docker image that you can use to run your Laravel project. It is based on [dunglas/frankenphp](https://github.com/dunglas/frankenphp). It also contains a `.devcontainer.json` file that you can use to create a new VS Code development environment.

## Requirements
- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) installed on your machine
- [VSCode](https://code.visualstudio.com/) (optional)

## Usage

1. Fork this repository
2. Go to Actions and click on the workflow `Build new Laravel project`
3. Click on the `Run workflow` button and fill in the form questions regarding your project
4. Wait for the workflow to finish
5. Clone your repository
6. Copy the env file from the `.env.example` file to the `.env` file
6. Run `docker-compose up -d` to start the Docker container
7. Open your project in VSCode

##  Production

The Docker container is configured also to run in production mode. You would need to target the `prod` build stage when building the image.

### Contributing

If you have any suggestions or improvements, feel free to open an issue or a pull request.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
