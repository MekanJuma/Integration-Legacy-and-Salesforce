public class OrgPersonEventProcessor {
    private List<OrgPersonEvent__e> events;
    private Map<String, Account> accountsToUpsert;
    private Map<String, Contact> contactsToUpsert;
    private Map<String, Set<PayloadParser.SourceData>> accountSources;
    private Map<String, Set<PayloadParser.RelationshipData>> contactRelationships;
    private Set<String> customerIds;
    private Set<String> personIds;

    public OrgPersonEventProcessor(List<OrgPersonEvent__e> events) {
        this.events = events;
        accountsToUpsert = new Map<String, Account>();
        contactsToUpsert = new Map<String, Contact>();
        accountSources = new Map<String, Set<PayloadParser.SourceData>>();
        contactRelationships = new Map<String, Set<PayloadParser.RelationshipData>>();
        customerIds = new Set<String>();
        personIds = new Set<String>();
    }
    
    private static void validateUpsertResult(String listName, List<Database.UpsertResult> results) {
        for (Database.UpsertResult result : results) {
            if (!result.isSuccess()) {
                Logger.log('Error upserting ' + listName + ': ' + result.getErrors()[0].getMessage());
            }
        }
    }
    
    public void process() {
        // Parsing events and preparing data for processing
        parseEvents();

        try {
            List<Account> accountList = new List<Account>(accountsToUpsert.values());
	    List<Database.UpsertResult> accountUpsertResults = Database.upsert(accountList, Account.Fields.Customer_ID__c, false);
	    validateUpsertResult('Account', accountUpsertResults);
            
            List<Contact> contactList = new List<Contact>(contactsToUpsert.values());
	    List<Database.UpsertResult> contactUpsertResults = Database.upsert(contactList, Contact.Fields.Person_Id__c, false);
            validateUpsertResult('Contact', contactUpsertResults);
            
            System.enqueueJob(new SourceHandlerQueueable(customerIds, accountsToUpsert, accountSources));
            System.enqueueJob(new ACRHandlerQueueable(personIds, contactsToUpsert, contactRelationships));
        } catch (Exception e) {
            Logger.logException(e);
        }
    }
    
    private void parseEvents() {
        for (OrgPersonEvent__e event : events) {
            PayloadParser.PayloadData parsedData = PayloadParser.parse(event.Payload__c);
            
            if (parsedData.accountData != null) {
                Account acc = new Account(
                    Name = parsedData.accountData.name,
                    Customer_ID__c = parsedData.accountData.customerId,
                    Out_of_Business_Date__c = parsedData.accountData.outOfBusinessDate,
                    Phone = parsedData.accountData.phone
                );
                accountsToUpsert.put(parsedData.accountData.customerId, acc);
                accountSources.put(parsedData.accountData.customerId, parsedData.accountData.sources);
                customerIds.add(parsedData.accountData.customerId);
            }
    
            if (parsedData.personData != null) {
                String primaryCustomerId = null;
                if (!parsedData.personData.relationships.isEmpty()) {
                    primaryCustomerId = parsedData.personData.relationships.iterator().next().customerId;
                }
                Contact con = new Contact(
                    Person_Id__c = parsedData.personData.personId,
                    FirstName = parsedData.personData.firstName,
                    LastName = parsedData.personData.midName,
                    RecordTypeId = getLegacyRecordType(),
                    AccountId = getPrimaryAccountId(primaryCustomerId)
                );
                contactsToUpsert.put(parsedData.personData.personId, con);
                contactRelationships.put(parsedData.personData.personId, parsedData.personData.relationships);
                personIds.add(parsedData.personData.personId);
            }
        }
    }
    
    private static Id getLegacyRecordType() {
        return [select Id, Name from RecordType where SobjectType = 'Contact' and DeveloperName = 'Legacy_System' Limit 1].Id;
    }
    
    private static Id getPrimaryAccountId(String customerId) {
        if (customerId == null) {
            return null;
        }
        
        Id primaryAccountId;
        List<Account> accs = [select Id from Account where Customer_ID__c = :customerId];
        if (!accs.isEmpty()) {
            primaryAccountId = accs[0].Id;
        } else {
            Account newAccount = new Account(Name = 'Primary Account: ' + customerId, Customer_ID__c = customerId);
            insert newAccount;
            
            primaryAccountId = newAccount.Id;
        }
	return primaryAccountId;
    }
    
    public class SourceHandlerQueueable implements Queueable {
        private Set<String> customerIds;
        private Map<String, Account> accountsMap;
        private Map<String, Set<PayloadParser.SourceData>> accountSources;

        public SourceHandlerQueueable(Set<String> customerIds, Map<String, Account> accountsMap, Map<String, Set<PayloadParser.SourceData>> accountSources) {
            this.customerIds = customerIds;
            this.accountsMap = accountsMap;
            this.accountSources = accountSources;
        }

        public void execute(QueueableContext context) {
            handleSources(customerIds, accountsMap, accountSources);
        }
        
        private void handleSources(Set<String> customerIds, Map<String, Account> accountsMap, Map<String, Set<PayloadParser.SourceData>> accountSources) {
            Map<String, Source__c> existingSourcesMap = new Map<String, Source__c>();
            List<Source__c> sourcesToInsert = new List<Source__c>();
        
            for (Source__c source : [SELECT Id, Account__r.Customer_ID__c, Source_System_Id__c FROM Source__c WHERE Account__r.Customer_ID__c IN :customerIds]) {
                existingSourcesMap.put(source.Account__r.Customer_ID__c + '-' + source.Source_System_Id__c, source);
            }
        
            for (String customerId : accountSources.keySet()) {
                for (PayloadParser.SourceData sourceData : accountSources.get(customerId)) {
                    String compositeKey = customerId + '-' + sourceData.sourceSystemId;
                    if (!existingSourcesMap.containsKey(compositeKey)) {
                        sourcesToInsert.add(new Source__c(
                            Account__c = accountsMap.get(customerId).Id,
                            Source_System__c = sourceData.sourceSystem,
                            Source_System_Id__c = sourceData.sourceSystemId
                        ));
                    }
                }
            }
        
            insert sourcesToInsert;
        }
    }
    
    public class ACRHandlerQueueable implements Queueable {
        private Set<String> personIds;
        private Map<String, Contact> contactsMap;
        private Map<String, Set<PayloadParser.RelationshipData>> contactRelationships;

        public ACRHandlerQueueable(Set<String> personIds, Map<String, Contact> contactsMap, Map<String, Set<PayloadParser.RelationshipData>> contactRelationships) {
            this.personIds = personIds;
            this.contactsMap = contactsMap;
            this.contactRelationships = contactRelationships;
        }

        public void execute(QueueableContext context) {
            handleACRs(personIds, contactsMap, contactRelationships);
        }
        
        private List<String> getValidRoles() {
            List<String> validRoles = new List<String>();
            Schema.DescribeFieldResult fieldResult = AccountContactRelation.Roles.getDescribe();
            for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                validRoles.add(entry.getValue());
            }
            return validRoles;
        }
        
        private void handleACRs(Set<String> personIds, Map<String, Contact> contactsMap, Map<String, Set<PayloadParser.RelationshipData>> contactRelationships) {
            Map<String, AccountContactRelation> existingACRMap = new Map<String, AccountContactRelation>();
            List<AccountContactRelation> acrToInsert = new List<AccountContactRelation>();
            Set<String> neededCustomerIds = new Set<String>();
            Map<String, Id> accountIdMap = new Map<String, Id>();
        
            for (String personId : contactRelationships.keySet()) {
                for (PayloadParser.RelationshipData relData : contactRelationships.get(personId)) {
                    neededCustomerIds.add(relData.customerId);
                }
            }
        
            for (Account acc : [SELECT Id, Customer_ID__c FROM Account WHERE Customer_ID__c IN :neededCustomerIds]) {
                accountIdMap.put(acc.Customer_ID__c, acc.Id);
            }
        
            List<Account> accountsToInsert = new List<Account>();
            for (String customerId : neededCustomerIds) {
                if (!accountIdMap.containsKey(customerId)) {
                    Account newAccount = new Account(Name = 'Account: ' + customerId, Customer_ID__c = customerId);
                    accountsToInsert.add(newAccount);
                    accountIdMap.put(customerId, newAccount.Id); // Placeholder ID
                }
            }
            
            if (!accountsToInsert.isEmpty()) {
                insert accountsToInsert;
                for (Account acc : accountsToInsert) {
                    accountIdMap.put(acc.Customer_ID__c, acc.Id);
                }
            }
    
            for (AccountContactRelation acr : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId IN :personIds]) {
                existingACRMap.put(acr.AccountId + '-' + acr.ContactId, acr);
            }
            
            List<String> validRoles = getValidRoles();
            for (String personId : contactRelationships.keySet()) {
                for (PayloadParser.RelationshipData relData : contactRelationships.get(personId)) {
                    Id accountIdForRelation = accountIdMap.get(relData.customerId);
                    Contact contactForRelation = contactsMap.get(personId);
                    String acrKey = accountIdMap.get(relData.customerId) + '-' + personId;
                    
                    if (contactForRelation.AccountId == accountIdForRelation || existingACRMap.containsKey(acrKey)) {
                        continue;
                    }
                    
                    String role = validRoles.contains(relData.relationshipType) ? relData.relationshipType : 'Other';
                    acrToInsert.add(new AccountContactRelation(
                        AccountId = accountIdForRelation,
                        ContactId = contactForRelation.Id,
                        Roles = role
                    ));
                }
            }
    
            insert acrToInsert;
        }
    }
}
