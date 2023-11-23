# Integration between the Legacy system and Salesforce

# Assignment
Integration between Legacy and Salesforce using platform event. Use Apex trigger as the subscriber. You can use Workbench or Postman to trigger events to the event bus. Attached are the payload for Organization and Person. External IDs are "Customerld" for Account and "PersonID" for Contact object.
Design a solution that will parse Customer Payload. Upsert account record based on CustomerID. Source information will be a related list with the Account object. While adding Sources to a related list it should not create duplicate sources.
Upsert Person payload. Upsert contact record based on PersonID. "Relationship" represents a person who will be working with multiple Customers. A customer can work with multiple persons.
Error handling and test classes are a must.

# Solution Overview
The solution integrates a legacy system with Salesforce using a platform event, which is triggered by external systems through Workbench or Postman. The integration involves processing payloads for organizations and persons to manage accounts and contacts within Salesforce, ensuring the handling of relationships and source information effectively.

# Key Components of the Solution
**1. Platform Event Setup:**
- **Name**: OrgPersonEvent.
- **Field**: Payload__c (Long Text) to store JSON data.
![Platform Event](https://github.com/MekanJuma/Integration-Legacy-and-Salesforce/blob/main/screenshots/platform%20event.PNG)

**2. Custom Object for Sources:**
- **Name**: Source__c.
- **Fields**: Account (Lookup), Source System (Text), Source System Id (Text).

**3. External ID Fields:**
- **Account**: Customer_ID__c (External ID, unique).
- **Contact**: Person_ID__c (External ID, unique).
 
**4. User Interface Adjustments:**
- Account Layout: Add 'Sources' and 'Related Contacts' related lists.
- Contact Layout: Add 'Related Accounts'.

**5. Feature Enabling:**
- Enable 'Contact to Multiple Accounts' feature to allow creating many-to-many relationships between Accounts and Contacts using AccountContactRelation object.

**6. Custom Settings:**
- To toggle the trigger's execution.
- Label: "Trigger Settings"
- Object Name: "Trigger_Settings"
- Custom Field: Is Trigger Active (Checkbox)
- Click Manage, and create a new org-wide default, and check the "Is Trigger Active" checkbox to enable the trigger.
![Custom Settings 1](https://github.com/MekanJuma/Integration-Legacy-and-Salesforce/blob/main/screenshots/custrom%20settings%201.PNG)
![Custom Settings 2](https://github.com/MekanJuma/Integration-Legacy-and-Salesforce/blob/main/screenshots/custom%20settings%202.PNG)

**7. Apex Trigger:**
- On OrgPersonEvent__e to handle the incoming event data.

**8. Supporting Apex Classes:**
- **PayloadParser**: Parses the JSON payload.
- **OrgPersonEventProcessor**: Processes the parsed data to upsert records.
- **Logger**: Handles exceptions and logs errors.

**9. Test Class:**
- **OrgPersonEventTriggerTest** to validate the functionality.

**10. Debug Logs**
- Open Debug Logs from Setup page
- Click New
- Traced Entity Type: Automated Process
- Start Date: select datetime (now)
- End Date: select datetime (now + 12 hours)
- Debug Level: Choose default or custom debug level 

**11. Testing via Workbench:**
- Utilize Workbench for posting payloads to Salesforce.
- Login Workbench
- Open REST Explorer
- POST request with the payload converting to string and assigning to Payload__c platform event field
- URL: /services/data/v58.0/sobjects/OrgPersonEvent__e
```
{
"Payload__c": "{\r\n   \"Person\":{\r\n      \"Header\":{\r\n         \"EventType\":\"Update\",\r\n         \"PersonID\":\"1049297410\",\r\n         \"PartyType\":\"Person\",\r\n         \"EventDTM\":\"2022-02-24T18:21:56.588Z\"\r\n      },\r\n      \"BaseObject\":{\r\n         \"MidName\":\"Jumayev\",\r\n         \"FirstName\":\"Mekan\",\r\n         \"PersonID\":\"1049297410\"\r\n      },\r\n      \"Relationship\":[\r\n         {\r\n            \"CustomerID\":\"4232323233\",\r\n            \"RelationshipType\":\"CustomerContact\",\r\n            \"PersonID\":\"1049297410\"\r\n         },\r\n         {\r\n            \"CustomerID\":\"109109104\",\r\n            \"RelationshipType\":\"CustomerContact\",\r\n            \"PersonID\":\"1049297410\"\r\n         }\r\n      ]\r\n   }\r\n}\r\n"
}
```
![Workbench](https://github.com/MekanJuma/Integration-Legacy-and-Salesforce/blob/main/screenshots/workbench.PNG)

# Solution Workflow
**Customer Data Handling**
- Parses the event payload for customer data.
- Upserts Account records based on CustomerID.
- Checks for existing sources under each Account and adds new sources without creating duplicates.

**Person Data Handling**
- Parses event payload for person data.
- Determines the primary Account for the Contact based on the first relationship in the payload. Creates the Account if it does not exist.
- Upserts Contacts, assigning them to the primary Account.
- Processes relationship data, creating new Accounts as needed.
- Manages AccountContactRelation records, ensuring no direct and indirect relationship conflicts.

**Notes**
- Platform Event Payloads are expected in JSON format.
- Contacts must not be private (must be associated with an Account) and cannot be directly associated with the same Account they are indirectly related to via AccountContactRelation.  
- When Contacts to Multiple Accounts is enabled, an Account Contact Relationship record is created for each contact with a primary account.


