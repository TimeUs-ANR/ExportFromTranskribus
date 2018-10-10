import requests
import json
from bs4 import BeautifulSoup
from config import username, password, status, collectionnames


# INTERACTION WITH TRANSKRIBUS

def authentificate():
    """Authentificate user on Transkribus and get a session ID.

    :return: session ID
    :rtype: string
    """
    url = "https://transkribus.eu/TrpServer/rest/auth/login"
    payload = 'user=' + username + '&' + 'pw=' + password
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    response = requests.request("POST", url, data=payload, headers=headers)

    try:
        soup = BeautifulSoup(response.text, "xml")
        id_session = soup.sessionId.string
        print("User successfully authentified.")
    except Exception as e:
        print("Authentification failed:")
        print(e)
        id_session = ''
    return id_session


def list_user_s_collections(id_session):
    """Get a list of all collections accessible to the authentified user on Transkribus in the form of a list of names and IDs as tuples.

    :param id_session: session ID
    :type id_session: string
    :return: list of collection names and IDs
    :rtype: list"""

    url = "https://transkribus.eu/TrpServer/rest/collections/list"
    querystring = {"JSESSIONID": id_session}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)

    collection_list = []
    [collection_list.append((collection["colName"], collection["colId"])) for collection in json_file]
    return collection_list

# VERIFY INPUT DATA
def verify_input_type(username, password, status, collectionnames):
    """Takes data input from configuration file and verify their type.

    :param username: user name
    :type username: any
    :param password: password
    :type password: any
    :param status: file status
    :type status: any
    :param collectionnames: collection names
    :type collectionnames: any
    :return: number of type errors
    :rtype: int
    """
    errors = []
    if not(isinstance(username, str)):
        errors.append("username must be a string. ")
    if not(isinstance(password, str)):
        errors.append("password must be a string. ")
    if not(isinstance(status, list)):
        errors.append("status must be a list. ")
    if not(isinstance(collectionnames, list)):
        errors.append("collectionnames must be a list. ")
    if len(errors) > 0:
        print("Invalid data input: %s" % (str(errors).strip("['']")))
    return len(errors)


def validate_status(status):
    """Takes a list of status given in configuration file and verify their validity.

    :param status: list of statuses
    :type status: list
    :return: list of valid statuses
    :rtype: list
    """
    ref_status = ["NEW", "IN PROGRESS", "DONE", "FINAL"]
    status_valid = []
    status_invalid = []
    for stat in status:
        stat_up = stat.upper()
        if stat_up in ref_status:
            status_valid.append(stat_up)
        else:
            status_invalid.append(stat)
    if len(status_invalid) > 0:
        print("Invalid status input: %s" % (str(status_invalid).strip('[]')))
    if len(status_valid) == 0:
        print("No valid status to work with. Please correct status list in config.py!")
    return status_valid

# SCRIPT BODY ---------------------------------------------------------------------------------------------------------

errors_input_type = verify_input_type(username, password, status, collectionnames)
if errors_input_type == 0:
    status_valid = validate_status(status)
    if len(status_valid) > 0:
        id_session = authentificate()
        if id_session:
            collection_list = list_user_s_collections(id_session)

            # compare collection of list accessible to user and collectionnames given in input
            # start extracting process.


