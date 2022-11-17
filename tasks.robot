*** Settings ***
Documentation       Adds the orders from the input "orders.csv" to the robotsparebinindustries orders page.
...                 Generates a pdf for each order processed and adds all files to a compressed folder.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Robocorp.Vault
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Dialogs
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${finalfolder}=     ${OUTPUT_DIR}${/}finaldocs${/}


*** Tasks ***
Execute orders
    ${input_url}=    Get input file url
    Open website
    Click OK button
    Download input file    ${input_url}
    #Read input file    #processes orders and creates pdfs
    ${orders}=    read file
    Fill and submit the orders    ${orders}
    Compress output folder
    [Teardown]    Close the browser


*** Keywords ***
Get input file url
    Add heading    Provide the url to download the orders file
    Add text input    url    placeholder=www.website.com/inputfile
    ${input_url}=    Run dialog
    Log    ${input_url}
    RETURN    ${input_url}

Open website
    ${url}=    Get Secret    SecretWeb
    Open Available Browser    ${url}[url]    #https://robotsparebinindustries.com/#/robot-order

Download input file
    [Arguments]    ${input_url}
    Download    ${input_url.url}    overwrite=True    verify=False    #http://robotsparebinindustries.com/orders.csv

Read input file
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Fill and submit the order    ${order}
    END

read file
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Fill and submit the orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Fill and submit the order    ${order}
    END

Fill and submit the order
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://*[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Click Button    Order
    Wait Until Keyword Succeeds    3    0.1s    Validate error
    #Validate error
    Capture preview of robot    ${order}[Order number]
    Generate pdf    ${order}[Order number]
    Click Button    Order another robot
    Click OK button

Capture preview of robot
    [Arguments]    ${order_no}
    Screenshot    //*[@id="robot-preview-image"]    ${OUTPUT_DIR}${/}robot_${order_no}.png

Order another robot
    Click Button    Order another robot

Click OK button
    Click Button    OK

Validate error
    ${ErrorOrdering}=    Does Page Contain Element    //*[@class='alert alert-danger']
    WHILE    ${ErrorOrdering} == True
        Click Button    Order
        ${ErrorOrdering}=    Does Page Contain Element    //*[@class='alert alert-danger']
    END

Generate pdf
    [Arguments]    ${order_no}
    ${order_details}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${order_details}    ${OUTPUT_DIR}${/}finaldocs${/}${order_no}.pdf
    Open Pdf    ${OUTPUT_DIR}${/}finaldocs${/}${order_no}.pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}robot_${order_no}.png
    ...    ${OUTPUT_DIR}${/}finaldocs${/}${order_no}.pdf
    #Close Pdf    ${OUTPUT_DIR}${/}finaldocs${/}${order_no}.pdf
    Remove File    ${OUTPUT_DIR}${/}robot_${order_no}.png

Compress output folder
    Archive Folder With Zip    ${OUTPUT_DIR}${/}finaldocs    finaldocs.zip
    Remove Directory    ${OUTPUT_DIR}${/}finaldocs    recursive=True

Close the browser
    Close Browser
