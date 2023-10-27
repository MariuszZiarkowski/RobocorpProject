*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${OUTPUT_DIR}${/}temp
${zip_folder}                       ${OUTPUT_DIR}${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the website
    Download the CSV file
    Fill and submit the form for one robot order
    Set up directories
    Create ZIP package from PDF files
    [Teardown]    Close Browser


*** Keywords ***
Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

Fill and submit the form for one robot order
    ${orders}=    Read table from CSV    Orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        ${element}=    Execute Javascript
        ...    return document.querySelector('input[placeholder="Enter the part number for the legs"]')
        ${orderNumber}=    Set Variable    ${order}[Order number]
        Select From List By Index    head    ${order}[Head]
        Select Radio Button    body    ${order}[Body]
        Log    ${element.get_attribute('id')}
        Input Text    ${element.get_attribute('id')}    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Wait Until Element Is Enabled    id:preview
        Click Button    preview
        Wait Until Keyword Succeeds    5x    5 sec    Click Order Button
        Export the table as a PDF    ${orderNumber}
        Embed the robot screenshot to the receipt PDF file    ${orderNumber}
        Click Button    order-another
    END

Open the website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window

Close the annoying modal
    Click Button    OK

Export the table as a PDF
    [Arguments]    ${orderNumber}

    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt${orderNumber}.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:robot-preview-image
    ${robot-preview-image_html}=    Screenshot
    ...    id:robot-preview-image
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}preview${orderNumber}.png
    Open Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt${orderNumber}.pdf
    Adding files to pdf    ${orderNumber}
    Save Pdf    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt${orderNumber}.pdf

Adding files to pdf
    [Arguments]    ${orderNumber}
    ${files}=    Create List
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt${orderNumber}.pdf
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}preview${orderNumber}.png
    Add Files To Pdf    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt${orderNumber}.pdf

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Click Order Button
    Wait Until Element Is Enabled    id:order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${zip_folder}PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Close current browser
    Close Browser
