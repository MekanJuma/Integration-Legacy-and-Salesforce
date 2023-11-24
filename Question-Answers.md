# Interview Questions

**Question 1:** Platform Event Handling: Can you explain how you designed the Apex Trigger to handle the OrgPersonEvent__e Platform Event and why you chose this particular design pattern?

**Answer:**
- Design of Apex Trigger: The trigger on OrgPersonEvent__e is designed to act as an event subscriber. It parses the payload and performs upsert operations for Accounts and Contacts based on external IDs. The use of a handler class abstracts complex logic from the trigger body, promoting clean code and separation of concerns.

- Choice of Pattern: Platform Events offer a loosely coupled, event-driven architecture allowing for scalable integrations. This pattern facilitates real-time data synchronization between Salesforce and external systems while adhering to Salesforce best practices for asynchronous processing.

**Question 2:** Source Management: How did you ensure that duplicate Source__c records were not created when processing the event payload?

**Answer:**
- To prevent duplicate Source__c records, the trigger first queries existing sources related to the incoming Account. It then checks the incoming source data against these records. Only sources that don't have a matching record in Salesforce are inserted. This approach efficiently avoids duplicates and maintains data integrity.

**Question 3:** Contact to Multiple Accounts: Describe the logic you used to handle Contacts related to multiple Accounts, especially considering Salesforce's limitations regarding direct and indirect account associations.

**Answer:**
- To effectively handle Contacts associated with multiple Accounts, the solution first necessitates enabling the “Allow Contacts to be Related to Multiple Accounts” feature from Salesforce's Account Settings. This feature activation is fundamental as it introduces the AccountContactRelation object in Salesforce, which is junction obect for creating many-to-many relationships between Contacts and Accounts.

- Primary Account Assignment: For each Contact in the payload, the trigger identifies a primary Account, typically based on the first relationship provided in the payload data. This primary association ensures that Contacts are not considered private within Salesforce, aligning with the platform's data model requirements.

- Creating AccountContactRelation Records: Beyond the primary association, the trigger processes the relationship data to establish additional links between the Contact and other Accounts. It creates AccountContactRelation records for each of these associations, which allows a Contact to be related to multiple Accounts in various capacities.

- Avoiding Conflicts: The logic includes checks to avoid direct-indirect association conflicts. This means if a Contact is directly associated with an Account (as a primary association), the trigger ensures that an AccountContactRelation record for the same Account-Contact pair is not redundantly created. Because when we assign a contact as primary, SF automatically creates AccountContactRelation record for the primary account.

**Question 4:**	Test Coverage: In your test class, how did you simulate the platform event and ensure comprehensive coverage for different scenarios, including edge cases?

**Answer:**
- In the test class, OrgPersonEventTriggerTest, I simulate platform events by creating OrgPersonEvent__e records with mock payload data. The test asserts the creation of Accounts, Contacts, Sources, and AccountContactRelations, ensuring that the trigger handles various scenarios. I included different edge cases like missing data fields and complex relationship mappings to ensure comprehensive coverage.

**Question 5:**	Custom Settings Usage: Can you elaborate on how you utilized Custom Settings to control the trigger's execution and why this approach was chosen?

**Answer:**
- Custom Settings are utilized to enable or disable the trigger's execution. This allows administrators to control the trigger without modifying the code, offering flexibility in managing the integration. The trigger checks this setting at runtime; if disabled, it bypasses processing. This approach is beneficial for maintenance, testing, or in case of unexpected issues in production.

**Question 6:**	Error Handling: Discuss your strategy for error handling and logging in the trigger. How did you ensure that errors were captured effectively and did not disrupt the system's stability?

**Answer:**
- Strategy: Implemented a centralized error handling mechanism using a custom Logger class. This class captures exceptions, logs detailed error messages with stack traces, and optionally sends notifications if critical. The try-catch blocks in the trigger and handler classes ensure that exceptions are caught and processed by this logger.

- Monitoring: Beyond logging, I would implement a monitoring system using Salesforce's built-in tools like Event Monitoring or third-party monitoring services. This would allow for real-time alerts on exceptions or performance issues. Regular audits of log data and proactive monitoring of system performance indicators help in maintaining the health of the integration and quickly identifying any emerging issues.

- System Stability: By using Database.upsert with partial success allowed, the system captures errors at the record level without halting the entire operation. This approach ensures that a single problematic record doesn't disrupt the processing of others, enhancing system stability.

**Question 7:**	Performance Considerations: What steps did you take to ensure that your solution was optimized for performance, particularly concerning Salesforce governor limits?

**Answer:**
- Bulkification: Ensured all operations are bulkified, meaning the code can handle large volumes of data without hitting governor limits. This includes bulk queries and DML operations.

- Efficient Queries: Carefully structured SOQL queries to retrieve only necessary fields and records, minimizing query execution time and memory usage.

- Avoiding SOQL in Loops: Avoided SOQL queries inside loops to prevent hitting governor limits, especially in the processing of source records and account-contact relationships.

**Question 8:**	Design Decisions: Were there any particular challenges or considerations you encountered while designing this solution? How did you address them?

**Answer:**
- Challenge: One of the main challenges was handling the many-to-many relationships between Contacts and Accounts, considering Salesforce's model for direct and indirect associations.

- Solution: This was addressed by ensuring Contacts are always linked to a primary Account, and then using the AccountContactRelation object for additional associations, carefully checking to avoid conflicts in direct-indirect associations.

**Question 9:**	Integration Testing: How did you test the integration with the legacy system? What tools or methods did you use?

**Answer:**
- Methodology: Tested the integration using mock payloads in the Salesforce testing environment. This simulated the data structure and format expected from the legacy system.

- Tools: Utilized Salesforce's built-in testing framework for unit tests. For end-to-end integration tests, used Workbench to simulate Platform Event triggers and monitored the system's response and data integrity.

**Question 10:**	Future Maintenance: How have you structured your code to facilitate easy maintenance and potential enhancements in the future?

**Answer:**
- Modular Design: Structured the solution with a clear separation of concerns – trigger, business logic in handler classes, and a separate utility class for parsing. This modular design facilitates easy updates to specific parts without affecting the whole.

- Readability and Documentation: Prioritized code readability and included necessary documentation within the code, making it easier for future developers to understand and modify.

- Custom Settings for Flexibility: Used Custom Settings to control the trigger’s execution, allowing administrators to enable/disable functionality without code deployment, thus offering flexibility for future changes or temporary suspensions.

**Question 11:**	Design Decision on Platform Events: What led to your decision to use Platform Events for this integration, as opposed to other integration patterns like outbound messaging or REST API calls?

**Answer:**
- Platform Events were chosen for their event-driven, decoupled nature, facilitating real-time integration. Unlike REST API calls, which are synchronous and require instant response handling, Platform Events allow for asynchronous processing, making them more scalable and efficient for large data volumes. Compared to outbound messaging, Platform Events offer a more modern, robust solution with native Salesforce integration, and they don't rely on SOAP-based web services.

**Question 12:**	Event Sizing and Volume Handling: How did you account for the size and volume of the Platform Events, considering Salesforce governor limits and event bus throughput?

**Answer:**
- When working with Platform Events in Salesforce, it is important to consider the size and volume of the events to ensure that you stay within the Salesforce governor limits and the event bus throughput.

- To manage event size and volume, I optimized the payload structure to include only necessary data. For handling high volumes, I ensured the trigger and related classes were bulkified to process large batches of events efficiently. Additionally, I monitored event bus limits and designed the system to stay within Salesforce’s event delivery and size limitations, avoiding overloading the event bus.

**Event Size:**
- Governor Limits: Salesforce imposes a maximum event size limit, which is currently 1 MB. Ensure that the size of your individual Platform Events, including the payload and any additional fields, does not exceed this limit.

- Payload Design: Optimize the payload design to minimize the event size. Avoid including unnecessary fields or large data structures. Consider using field references or IDs instead of including complete records in the payload.

**Event Volume:**
- Publish Considerations: Evaluate the rate at which you need to publish events. Salesforce imposes limits on the number of events you can publish per 24-hour period. These limits vary based on your Salesforce edition and can be found in Platform Event page in Salesforce. Ensure that your event publishing rate stays within these limits.

**Question 13:**	Impact on Reporting: How does associating Contacts with multiple Accounts affect Salesforce reporting capabilities and data analysis?

**Answer:**
- Associating Contacts with multiple Accounts enhances reporting by providing a more comprehensive view of customer interactions and relationships. In Salesforce reports and dashboards, this allows for more detailed analysis of Contact interactions across different Accounts. However, it requires careful report design to accurately represent these many-to-many relationships and to avoid misinterpretation of data, especially in aggregations and summaries.

**Question 14:**	Trigger Framework: Did you consider using any trigger frameworks (like Trigger Handler patterns) for scalability and maintainability? Why or why not?

**Answer:**
- Yes, I considered using trigger frameworks like the Trigger Handler pattern for better organization and manageability. This pattern allows separating business logic from the trigger itself, making the code more maintainable and scalable. However, for this specific project, considering its scope and the need for streamlined processing of platform events, I opted for a more direct approach while still maintaining clear separation of concerns within the handler classes.

**Question 15:**	Code Reusability and Modular Design: How did you structure your classes and methods to promote reusability and modular design?

**Answer:**
- I structured the classes and methods with a focus on modular design. Each class has a single responsibility - parsing, processing, logging, etc. Methods were designed to perform specific tasks that could be reused across different parts of the application. This approach not only makes the codebase more manageable but also allows for easier updates and enhancements.

**Question 16:**	Asynchronous Processing Considerations: For the operations in your trigger, did you consider any asynchronous processing methods (like Queueable or Batch Apex)? If so, how did you decide where to apply them?

**Answer:**
- Asynchronous processing was considered for operations that are heavy or not time-sensitive. For example, handling large volumes of related records could be offloaded to a Queueable or Batch Apex to avoid hitting governor limits and ensure smoother processing. The decision to use asynchronous processing was based on the nature of the operation, data volume, and performance requirements.
