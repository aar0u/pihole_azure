#!/usr/bin/env python3
import os
import logging
from logging.handlers import RotatingFileHandler
import ipaddress
from flask import Flask, request
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient

app = Flask(__name__)

# Create logs directory if it doesn't exist
log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
os.makedirs(log_dir, exist_ok=True)

# Configure logging
log_file = os.path.join(log_dir, "nsg_updater.log")
file_handler = RotatingFileHandler(log_file, maxBytes=1024 * 1024, backupCount=5)
console_handler = logging.StreamHandler()

# Set format for logs
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)

# Configure root logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(file_handler)
logger.addHandler(console_handler)

# Reduce verbosity of Azure SDK logs
azure_logger = logging.getLogger("azure.core.pipeline.policies.http_logging_policy")
azure_logger.setLevel(logging.WARNING)

API_KEY = os.environ.get("API_KEY", "your-api-key")


def is_valid_ip(ip):
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False


def update_nsg_source_ip(new_ip):
    try:
        subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")
        resource_group = os.environ.get("AZURE_RESOURCE_GROUP")
        nsg_name = os.environ.get("AZURE_NSG_NAME")

        logger.info(f"Attempting to update NSG {nsg_name} in {resource_group}")
        credential = DefaultAzureCredential()
        network_client = NetworkManagementClient(credential, subscription_id)

        nsg = network_client.network_security_groups.get(resource_group, nsg_name)

        update_count = 0
        for rule in nsg.security_rules:
            if rule.source_address_prefix != "*":
                logger.info(
                    f"Updating rule: {rule.name} from {rule.source_address_prefix} to {new_ip}"
                )
                rule.source_address_prefix = new_ip
                update_count += 1

        if update_count > 0:
            network_client.network_security_groups.begin_create_or_update(
                resource_group, nsg_name, nsg
            ).result()
            logger.info(f"Successfully updated {update_count} rules with IP: {new_ip}")
        else:
            logger.warning("No rules were updated - no matching rules found")

        return f"OK: {new_ip}"
    except Exception as e:
        logger.error(f"Error updating NSG rules: {str(e)}", exc_info=True)
        raise


@app.route("/", methods=["GET"])
def nsg_controller():
    # Verify API key
    api_key = request.args.get("key")
    if not api_key or api_key != API_KEY:
        logger.warning(f"Invalid API key attempt from IP: {request.remote_addr}")
        return ""

    new_ip = request.args.get("q")
    if not new_ip:
        new_ip = request.remote_addr
        logger.info(f"No IP provided, using requester's IP: {new_ip}")
    elif not is_valid_ip(new_ip):
        logger.error(f"Invalid IP attempted: {new_ip}")
        return ""

    try:
        update_nsg_source_ip(new_ip)
        logger.info(f"Successfully updated NSG IP to {new_ip}")
        return ""
    except Exception as e:
        logger.error(f"Error updating NSG: {str(e)}")
        return ""


if __name__ == "__main__":
    # Bind to all available IP addresses
    app.run(host="0.0.0.0", port=5000)
