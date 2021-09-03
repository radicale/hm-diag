import logging
import datetime
import json

from hw_diag.utilities.blockchain import get_helium_blockchain_height
from hw_diag.utilities.hardware import get_ethernet_addresses
from hw_diag.utilities.hardware import get_rpi_serial
from hw_diag.utilities.hardware import detect_ecc
from hw_diag.utilities.hardware import set_diagnostics_bt_lte
from hw_diag.utilities.hardware import lora_module_test
from hw_diag.utilities.miner import get_public_keys
from hw_diag.utilities.miner import write_public_keys_to_diag
from hw_diag.utilities.miner import set_param_miner_diag
from hw_diag.utilities.shell import get_environment_var
from hm_hardware_defs.variant import variant_definitions


log = logging.getLogger()
log.setLevel(logging.DEBUG)


def perform_hw_diagnostics():
    log.info('Running periodic hardware diagnostics')

    diagnostics = {}

    now = datetime.datetime.utcnow()
    diagnostics['last_updated'] = now.strftime("%H:%M UTC %d %b %Y")

    get_ethernet_addresses(diagnostics)
    get_environment_var(diagnostics)
    get_rpi_serial(diagnostics)
    detect_ecc(diagnostics)

    diagnostics['LOR'] = lora_module_test()

    # Get the Public Key, Onboarding Key & Helium Animal Name
    try:
        keys = get_public_keys()
        write_public_keys_to_diag(keys, diagnostics)
    except PermissionError as e:
        logging.error(e)

    set_param_miner_diag(diagnostics)

    # If  symmetric NAT set miner to relayed.
    if diagnostics['MN'] == "symmetric":
        diagnostics['MR'] = True
    else:
        diagnostics['MR'] = False

    # Get the blockchain height from the Helium API
    value = "1"
    try:
        value = get_helium_blockchain_height()
    except KeyError as e:
        logging.warning(e)
    diagnostics['BCH'] = value

    # Check if the miner height
    # is within 500 blocks and if so say it's synced
    if int(diagnostics['MH']) > (int(diagnostics['BCH']) - 500):
        diagnostics['MS'] = True
    else:
        diagnostics['MS'] = False

    # Calculate a percentage for block sync
    diag_mh = int(diagnostics['MH'])
    diag_bch = int(diagnostics['BCH'])
    diagnostics['BSP'] = round(diag_mh / diag_bch * 100, 3)

    set_diagnostics_bt_lte(diagnostics)

    # Check if the region has been set
    try:
        with open("/var/pktfwd/region", 'r') as data:
            region = data.read()
            if len(region) > 3:
                log.info("Frequency: " + str(region))
                diagnostics['RE'] = str(region).rstrip('\n')
    except FileNotFoundError:
        # No region found, put a dummy region in
        diagnostics['RE'] = "UN123"

    # Check the basics if they're fine and set an overall value
    # Basics are: ECC valid, Mac addresses aren't FF, BT Is present,
    # and LoRa hasn't failed
    if (
            diagnostics["ECC"] is True
            and diagnostics["E0"] is not None
            and diagnostics["W0"] is not None
            and diagnostics["BT"] is True and diagnostics["LOR"] is True
    ):
        diagnostics["PF"] = True
    else:
        diagnostics["PF"] = False

    # Add variant variables into diagnostics
    # These are variables from the hardware definitions file
    try:
        variant_variables = variant_definitions[diagnostics['VA']]
        diagnostics.update(variant_variables)
    except KeyError:
        pass

    with open('diagnostic_data.json', 'w') as f:
        json.dump(diagnostics, f)

    log.info('Diagnostics complete')