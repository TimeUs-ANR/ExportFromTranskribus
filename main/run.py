import requests
import datetime
import os
import json
from bs4 import BeautifulSoup
from config import username, password, status, collectionnames

# CONSTANTS
now = datetime.datetime.now()
TIMESTAMP = "%s-%s-%s-%s-%s" % (now.year, now.month, now.day, now.hour, now.minute)

CWD = os.path.dirname(os.path.abspath(__file__))

# INTERACTION WITH OS

def create_directory(directory):
    """Create a new directory.

    :param directory: path to new directory
    :type directory: string
    """
    if not os.path.exists(directory):
        os.makedirs(directory)


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


def get_user_s_collections(id_session):
    """Get a list of all collections accessible to the authentified user on Transkribus in the form of a dictionnary with names as keys and IDs as values.

    :param id_session: session ID
    :type id_session: string
    :return: collection names and IDs
    :rtype: dict
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/list"
    querystring = {"JSESSIONID": id_session}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)

    collection_dict = {}
    [collection_dict.update({collection["colName"] : collection["colId"]}) for collection in json_file]
    return collection_dict


def list_id_document(id_session, id_collection):
    """Get a list of all documents contained by a collection in Transkribus.

    :param id_session: session ID
    :type id_session: string
    :param id_collection: collection ID
    :type id_collection: int
    :return: list of document ID
    :rtype: list
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/%s/list" % id_collection
    querystring = {"JSESSIONID": id_session}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)
    id_document_list = [document["docId"] for document in json_file]
    return id_document_list


def list_pages(id_session, id_collection, id_document):
    """Creates a list of all transcriptions available for the pages of a document with their metadata.

    :param id_session: session ID
    :type id_session: string
    :param id_collection: collection ID
    :type id_collection: int
    :param id_document: document ID
    :type id_document: int
    :return: tuple made of document's metadata and document's list of transcripts
    :rtype: tuple
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/%s/%s/fulldoc" % (id_collection, id_document)
    querystring = {"JSESSIONID": id_session}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)
    page_list = json_file["pageList"]["pages"]
    metadata = json_file["md"]
    return metadata, page_list

# VERIFICATIONS (status, collection names) and authentification
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
    print("Invalid input: %s" % (str(errors).strip("['']")))
else:
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
        print("No valid status to work with. Please correct list of statuses in config.py!")
    else:
        all_status = " ".join(status_valid)
        id_session = authentificate()
        if id_session:
            path_to_temp_dir = os.path.join(CWD, "temp")
            path_to_main_dir = os.path.join(path_to_temp_dir, TIMESTAMP)
            create_directory(path_to_main_dir)

            user_collections_dict = get_user_s_collections(id_session)
            if len(user_collections_dict) > 0:
                id_collection_list = []
                for input_collection_name in collectionnames:
                    if input_collection_name in user_collections_dict:
                        id_collection_list.append((user_collections_dict[input_collection_name], input_collection_name))
                    else:
                        print("User has no access to \"%s\" or this collection does not exist." % input_collection_name)
                if len(id_collection_list) == 0:
                    print("No valid collection to work with. Please, correct list of collection names in config.py!")
                else:
                    # EXPORTING transcriptions from Transkribus by collection, document, page
                    for id_collection, name_collection in id_collection_list:
                        id_document_list = list_id_document(id_session, id_collection)
                        if len(id_document_list) == 0:
                            print("No document in %s.") % name_collection
                        else:
                            all_collection = ''
                            all_collection = all_collection + name_collection + ";\n"
                            path_to_coll_dir = os.path.join(path_to_main_dir, name_collection)
                            create_directory(path_to_coll_dir)

                            for id_document in id_document_list:
                                metadata, page_list = list_pages(id_session, id_collection, id_document)
                                doc_title = metadata["title"]
                                doc_uploader = metadata["uploader"]
                                if "desc" in metadata:
                                   doc_desc = metadata["desc"]
                                else:
                                    doc_desc = "No description"
                                if "language" in metadata:
                                    doc_lang = metadata["language"]
                                else:
                                    doc_lang = ""
                                d = doc_title.replace("/", "-").replace("\\", "-")
                                path_to_doc_dir = os.path.join(path_to_coll_dir, "%s - %s") % (id_document, d)

                                # ADDING data into PAGE files under 'temp' name space
                                for page in page_list:
                                    page_status = page["tsList"]["transcripts"][0]["status"]
                                    page_ts_url = page["tsList"]["transcripts"][0]["url"]
                                    page_img_url = page["url"]
                                    page_nb = page["tsList"]["transcripts"][0]["pageNr"]
                                    if page_status in status_valid:
                                        exported_transcript = requests.request("GET", page_ts_url)
                                        if not(exported_transcript.status_code == 200):
                                            print("Error : status code %s when exporting page %s of \"%s\"") % (exported_transcript.status_code, page_nb, doc_title)
                                        else:
                                            create_directory(path_to_doc_dir)
                                            path_to_transcript = os.path.join(path_to_doc_dir, "%s - %s.xml") % (page_nb, page_status)

                                            t_title = "<title>%s</title>" % doc_title
                                            tag_title = BeautifulSoup(t_title, "xml")
                                            tag_title = tag_title.title.extract()
                                            tag_title.name = "temp:title"

                                            t_desc = "<desc>%s</desc>" % doc_desc
                                            tag_desc = BeautifulSoup(t_desc, "xml")
                                            tag_desc = tag_desc.desc.extract()
                                            tag_desc.name = "temp:desc"

                                            t_nb = "<pagenumber>%s</pagenumber>" % page_nb
                                            tag_nb = BeautifulSoup(t_nb, "xml")
                                            tag_nb = tag_nb.pagenumber.extract()
                                            tag_nb.name = "temp:pagenumber"

                                            t_status = "<tsStatus>%s</tsStatus>" % page_status
                                            tag_status = BeautifulSoup(t_status, "xml")
                                            tag_status = tag_status.tsStatus.extract()
                                            tag_status.name = "temp:tsStatus"

                                            if len(doc_lang) > 0:
                                                doc_lang = ''.join(["<language>%s<language>" % l.strip() for l in doc_lang.split(",")])
                                                doc_lang = "<languages>%s</languages>" % doc_lang
                                                tag_lang = BeautifulSoup(doc_lang, "xml")
                                                tag_lang = tag_lang.languages.extract()
                                                tag_lang_list = tag_lang.findAll("language")
                                                for tag in tag_lang_list:
                                                    tag.name = "temp:language"

                                            soup = BeautifulSoup(exported_transcript.text, "xml")
                                            if soup.PcGts:
                                                soup.PcGts["xmlns:temp"] = "temporary"
                                                soup.Page["temp:id"] = page_nb
                                                soup.Page["temp:urltoimg"] = page_img_url
                                                soup.Metadata.append(tag_title)
                                                soup.Metadata.append(tag_desc)
                                                soup.Metadata.append(tag_nb)
                                                soup.Metadata.append(tag_status)
                                                if len(doc_lang) > 0:
                                                    for tag in tag_lang_list:
                                                        soup.Metadata.append(tag)
                                                with open(path_to_transcript, "w") as f:
                                                    f.write(str(soup))
                    # Reporting on the export
                    path_to_report = os.path.join(path_to_main_dir, "general-report.txt")
                    report = "Export request ran on %s/%s/%s at %s:%s.\nFrom user '%s', exported transcripts with status '%s' from following collections:\n %s" % (now.day, now.month,now.year, now.hour, now.minute, username, all_status, all_collection)
                    with open(path_to_report, "w") as f:
                        f.write(report)
                    print("Successfully exported transcriptions from Transkribus!")
                    print("Files are stored in %s directory." % path_to_main_dir)
