# -*- coding: utf-8 -*-

import requests
import datetime
import os
import json
import subprocess
from bs4 import BeautifulSoup
from config import username, password, status, collections, documents

# CONSTANTS
now = datetime.datetime.now()
TIMESTAMP = "%s-%s-%s-%s-%s" % (now.year, now.month, now.day, now.hour, now.minute)
CWD = os.path.dirname(os.path.abspath(__file__))
SAXON_JAR = "saxon9he.jar"      # Change value if using a different version of Saxon
                                # Saxon file must be placed in "main/" directory
PAGE2TEI = "page2tei_TU.xsl"    # Change value if using a different version of Page2tei XSLT
                                # Page2tei file must be place in "main/" directory


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
        session_id = soup.sessionId.string
        print("User successfully authentified.")
    except Exception as e:
        print("Authentification failed: username or password are not correct. Check {}/config.py".format(CWD))
        session_id = ''
    return session_id


def get_user_s_collections(session_id):
    """Get a list of all collections accessible to the authentified user on Transkribus in the form of a dictionnary with names as keys and IDs as values.

    :param session_id: session ID
    :type session_id: string
    :return: collection names and IDs
    :rtype: dict
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/list"
    querystring = {"JSESSIONID": session_id}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)

    coll_user_s = {}
    [coll_user_s.update({collection["colName"]: collection["colId"]}) for collection in json_file]
    return coll_user_s


def list_document_id(session_id, coll_id):
    """Get a list of all documents contained by a collection in Transkribus.

    :param session_id: session ID
    :type session_id: string
    :param coll_id: collection ID
    :type coll_id: int
    :return: list of document ID
    :rtype: list
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/%s/list" % coll_id
    querystring = {"JSESSIONID": session_id}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)
    doc_id_l = [document["docId"] for document in json_file]
    return doc_id_l


def verify_documents_id(id_list):
    """ Verify the validity of document ids.

    :param id_list: list of document ID
    :type id_list: list
    :return: list of document ID
    :rtype: list
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/%s/list" % coll_id
    querystring = {"JSESSIONID": session_id}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)
    doc_id_l = [document["docId"] for document in json_file if str(document["docId"]) in id_list]
    return doc_id_l


def list_pages(session_id, coll_id, doc_id):
    """Creates a list of all transcriptions available for the pages of a document with their metadata.

    :param session_id: session ID
    :type session_id: string
    :param coll_id: collection ID
    :type coll_id: int
    :param doc_id: document ID
    :type doc_id: int
    :return: tuple made of document's metadata and document's list of transcripts
    :rtype: tuple
    """
    url = "https://transkribus.eu/TrpServer/rest/collections/%s/%s/fulldoc" % (coll_id, doc_id)
    querystring = {"JSESSIONID": session_id}
    response = requests.request("GET", url, params=querystring)
    json_file = json.loads(response.text)
    page_l = json_file["pageList"]["pages"]
    metadata = json_file["md"]
    return metadata, page_l


# VERIFICATIONS (status, collection names) and authentification
errors = []
if not (isinstance(username, str)):
    errors.append("username must be a string. ")
if not (isinstance(password, str)):
    errors.append("password must be a string. ")
if not (isinstance(status, list)):
    errors.append("status must be a list. ")
if not (isinstance(collections, list)):
    errors.append("collections must be a list. ")

if len(errors) > 0:
    print("Invalid input: %s" % (str(errors).strip("['']")))
else:
    status_ref = ["NEW", "IN_PROGRESS", "DONE", "FINAL"]
    status_valid = []
    status_invalid = []
    for stat in status:
        stat_up = stat.upper()
        if stat_up in status_ref:
            status_valid.append(stat_up)
        else:
            status_invalid.append(stat)
    if len(status_invalid) > 0:
        print("Invalid status input: %s" % (str(status_invalid).strip('[]')))

    if len(status_valid) == 0:
        print("No valid status to work with. Please correct list of statuses in config.py!")
    else:
        status_all = " ".join(status_valid)
        session_id = authentificate()
        if session_id:
            path_to_temp_dir = os.path.join(CWD, "temp")
            path_to_export_dir = os.path.join(path_to_temp_dir, TIMESTAMP)
            create_directory(path_to_export_dir)

            coll_user_s = get_user_s_collections(session_id)
            if len(coll_user_s) > 0:
                coll_id_l = []
                coll_all = ''
                for coll_input in collections:
                    if coll_input in coll_user_s:
                        coll_id_l.append((coll_user_s[coll_input], coll_input))
                    else:
                        print("User has no access to \"%s\" or this collection does not exist." % coll_input)
                if len(coll_id_l) == 0:
                    print("No valid collection to work with. Please, correct list of collection names in config.py!")
                else:
                    # EXPORTING transcriptions from Transkribus by collection, document, page
                    for coll_id, coll_name in coll_id_l:
                        # Introducing the documents parameter
                        if len(documents) == 0 or len(documents[0]) == 0:
                            doc_id_l = list_document_id(session_id, coll_id)
                        else:
                            doc_id_l = verify_documents_id(documents)
                        if len(doc_id_l) == 0:
                            print("No document in %s, or no valid document IDs in input." % coll_name)
                        else:
                            coll_all = coll_all + coll_name + ";\n"
                            path_to_coll_dir = os.path.join(path_to_export_dir, coll_name)
                            create_directory(path_to_coll_dir)

                            for doc_id in doc_id_l:
                                metadata, page_l = list_pages(session_id, coll_id, doc_id)
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
                                path_to_doc_dir = os.path.join(path_to_coll_dir, "%s - %s") % (doc_id, d)

                                # ADDING data into PAGE files under 'temp' name space
                                for page in page_l:
                                    page_status = page["tsList"]["transcripts"][0]["status"]
                                    page_url_ts = page["tsList"]["transcripts"][0]["url"]
                                    page_url_img = page["url"]
                                    page_nb = page["tsList"]["transcripts"][0]["pageNr"]
                                    if page_status in status_valid:
                                        exported_transcript = requests.request("GET", page_url_ts)
                                        if not (exported_transcript.status_code == 200):
                                            print("Error : status code %s when exporting page %s of \"%s\"") % (exported_transcript.status_code, page_nb, doc_title)
                                        else:
                                            create_directory(path_to_doc_dir)
                                            path_to_transcript = os.path.join(path_to_doc_dir, "%s - %s.xml") % (page_nb, page_status)

                                            t_title = "<title>%s</title>" % doc_title
                                            tag_title = BeautifulSoup(t_title, "xml")
                                            tag_title = tag_title.title.extract()
                                            tag_title.name = "temp:title"

                                            t_uploader = "<uploader>%s</uploader>" % doc_uploader
                                            tag_uploader = BeautifulSoup(t_uploader, "xml")
                                            tag_uploader = tag_uploader.uploader.extract()
                                            tag_uploader.name = "temp:uploader"

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
                                                soup.Page["temp:urltoimg"] = page_url_img
                                                soup.Metadata.append(tag_title)
                                                soup.Metadata.append(tag_desc)
                                                soup.Metadata.append(tag_nb)
                                                soup.Metadata.append(tag_status)
                                                soup.Metadata.append(tag_uploader)
                                                if len(doc_lang) > 0:
                                                    for tag in tag_lang_list:
                                                        soup.Metadata.append(tag)
                                                with open(path_to_transcript, "w") as f:
                                                    f.write(str(soup))
                    # REPORTING on the export
                    if len(coll_all) > 0:
                        path_to_report = os.path.join(path_to_export_dir, "general-report.txt")
                        report = "Export request ran on %s/%s/%s at %s:%s.\nFrom user '%s', exported transcripts with status '%s' from following collections:\n %s" % (now.day, now.month, now.year, now.hour, now.minute, username, status_all, coll_all)
                        with open(path_to_report, "w") as f:
                            f.write(report)
                        print("Successfully exported transcriptions from Transkribus!")

                    # TRANSFORMING PAGE files to TEI
                        env = dict(os.environ)
                        env["JAVA_OPTS"] = "foo"
                        path_to_parser = os.path.join(CWD, SAXON_JAR)
                        path_to_xslt = os.path.join(CWD, PAGE2TEI)

                        coll_dir_l = os.listdir(path_to_export_dir)
                        xslt_coll_l = []
                        for item in coll_dir_l:
                            path_abs = os.path.join(path_to_export_dir, item)
                            if os.path.isdir(path_abs) is True:
                                xslt_coll_l.append(path_abs)

                        if len(coll_dir_l) > 0:
                            xslt_doc_l = []
                            for coll_dir in xslt_coll_l:
                                doc_dir_l = os.listdir(coll_dir)
                                for item in doc_dir_l:
                                    path_abs = os.path.join(coll_dir, item)
                                    if os.path.isdir(path_abs) is True:
                                        xslt_doc_l.append(item)

                                errors = 0
                                for xslt_input in xslt_doc_l:
                                    xslt_output = os.path.join(coll_dir, "TEI - %s" % xslt_input)
                                    xslt_input = os.path.join(coll_dir, xslt_input)
                                    create_directory(xslt_output)
                                    xslt_output = "-o:" + xslt_output
                                    xslt_input = "-s:" + xslt_input
                                    result = subprocess.call(
                                        ["java", "-jar", path_to_parser, xslt_input, xslt_output, path_to_xslt], env=env)
                                    if not result == 0:
                                        errors += 1
                            if errors == 0:
                                print("Successfully transformed exported PAGE XML files to TEI XML!")
                            else:
                                print("Errors encountered while transforming exported XML files to TEI XML!")
                        print("Files are stored in %s directory." % path_to_export_dir)

                    else:
                        print("Could not export transcriptions from Transkribus.")
