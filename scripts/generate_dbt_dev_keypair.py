from pathlib import Path
from getpass import getpass
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

folder = Path(".keys")
folder.mkdir(exist_ok=True)

private_path = folder / "dbt_dev_key.p8"
public_path = folder / "dbt_dev_key.pub"

if private_path.exists() or public_path.exists():
    raise SystemExit("dbt key files already exist. Nothing was overwritten.")

password = getpass("Create a dbt private-key passphrase: ")
confirmation = getpass("Confirm the passphrase: ")

if not password or password != confirmation:
    raise SystemExit("Passphrases are empty or do not match. Run again.")

key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048
)

private_path.write_bytes(key.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.BestAvailableEncryption(password.encode())
))

public_path.write_bytes(key.public_key().public_bytes(
    serialization.Encoding.PEM,
    serialization.PublicFormat.SubjectPublicKeyInfo
))

print("PASS: encrypted dbt development key pair created.")
