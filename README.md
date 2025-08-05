# Counter Strike Manager Migrations

This project manages database migrations for Counter Strike Manager.

## Environment Variables

Set the following environment variables before running the migrations.  
You can initialize them easily in a Bash shell with:

```bash
set -a && source .env
```

Example `.env` file:

```env
DB_HOST=localhost
DB_USER=YOUR_USER
DB_PASSWORD=YOUR_PASSWORD
DB_NAME=counter_strike
DB_PORT=5432
DB_INSECURE=true

MAX_IDLE_CONN=1
MAX_OPEN_CONN=1
```

## Usage

1. Clone the repository.
2. Create and configure your `.env` file with the required variables.
3. Initialize the environment variables in your shell:
    ```bash
    set -a && source .env
    ```
4. Run the migrations as described in the project documentation.

## License

This project is licensed under the MIT License.