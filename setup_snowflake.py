import os
import pathlib

config = """[connections.default]
account = "{account}"
user = "{user}"
password = "{password}"
role = "{role}"
warehouse = "{warehouse}"
database = "{database}"
schema = "{schema}"
""".format(
    account=os.environ["SF_ACCOUNT"],
    user=os.environ["SF_USER"],
    password=os.environ["SF_PASSWORD"],
    role=os.environ["SF_ROLE"],
    warehouse=os.environ["SF_WAREHOUSE"],
    database=os.environ["SF_DATABASE"],
    schema=os.environ["SF_SCHEMA"],
)

config_path = pathlib.Path.home() / ".snowflake" / "config.toml"
config_path.parent.mkdir(parents=True, exist_ok=True)
config_path.write_text(config)
config_path.chmod(0o600)
print("config.toml criado com sucesso")
