@isTest
private class OrgPersonEventTriggerTest {

    @isTest static void testOrgPersonEventTrigger() {
        Trigger_Settings__c settings = new Trigger_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Is_Trigger_Active__c = true
        );
        insert settings;
        
        String customerPayload = '{"Customer":{"Header":{"CustomerID":"104736896","EventType":"Update","PartyType":"Customer"},"BaseObject":{"OutOfBusinessDate":"","Name":"MAINER AUTO GROUP II LP","CustomerID":"104736896"},"Phone":[{"PhoneType":"Main Phone","PhoneNumber":"(918) 367-3373"}],"Sources":[{"SourceSystem": "TLC","SourceSystemID": "50581"}, {"SourceSystem": "BTC","SourceSystemID": "131346506467498"}, {"SourceSystem": "GLC","SourceSystemID": "6046656"}]}}';
        String personPayload = '{"Person":{"Header":{"EventType":"Update","PersonID":"104929748","PartyType":"Person","EventDTM":"2022-02-24T18:21:56.588Z"},"BaseObject":{"MidName":"Zamir","FirstName":"Omar","PersonID":"104929748"},"Relationship":[{"CustomerID":"104648687","RelationshipType":"CustomerContact","PersonID":"104929748"},{"CustomerID":"104736896","RelationshipType":"CustomerContact","PersonID":"104929748"}]}}';

        List<OrgPersonEvent__e> publishEvents = new List<OrgPersonEvent__e>();
        publishEvents.add(new OrgPersonEvent__e(Payload__c = customerPayload));
        publishEvents.add(new OrgPersonEvent__e(Payload__c = personPayload));

        Test.startTest();
        EventBus.publish(publishEvents);
        Test.stopTest();

        Account createdAccount = [SELECT Id, Name, Customer_ID__c FROM Account WHERE Customer_ID__c = '104736896' LIMIT 1];
        System.assertNotEquals(null, createdAccount, 'Account should be created.');

        Contact createdContact = [SELECT Id, FirstName, LastName, Person_Id__c FROM Contact WHERE Person_Id__c = '104929748' LIMIT 1];
        System.assertNotEquals(null, createdContact, 'Contact should be created.');

        List<AccountContactRelation> acrList = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId = :createdContact.Id];
	System.assertEquals(2, acrList.size(), 'Two AccountContactRelations should be created');

        List<Source__c> sourceList = [SELECT Id, Account__c, Source_System__c, Source_System_Id__c FROM Source__c WHERE Account__c = :createdAccount.Id];
        System.assertEquals(3, sourceList.size(), 'Three Source__c records should be created.');
    }
}
