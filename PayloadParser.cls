public class PayloadParser {

    public class AccountData {
        public String name;
        public String customerId;
        public String outOfBusinessDate;
        public String phone;
        public Set<SourceData> sources = new Set<SourceData>();
    }

    public class SourceData {
        public String sourceSystem;
        public String sourceSystemId;
    }

    public class PersonData {
        public String personId;
        public String firstName;
        public String midName;
        public Set<RelationshipData> relationships = new Set<RelationshipData>();
    }

    public class RelationshipData {
        public String customerId;
        public String relationshipType;
    }

    public class PayloadData {
        public AccountData accountData;
        public PersonData personData;
    }

    public static PayloadData parse(String jsonPayload) {
        // we can record particular payload creating a custom object to be tracked incoming payloads
        PayloadData payloadData = new PayloadData();

        String unescapedJson = jsonPayload.unescapeJava();
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(unescapedJson);

        Map<String, Object> customerMap = (Map<String, Object>) payloadMap.get('Customer');
        if (customerMap != null) {
            payloadData.accountData = parseAccountData(customerMap);
        }

        Map<String, Object> personMap = (Map<String, Object>) payloadMap.get('Person');
        if (personMap != null) {
            payloadData.personData = parsePersonData(personMap);
        }

        return payloadData;
    }

    private static AccountData parseAccountData(Map<String, Object> customerMap) {
        AccountData accountData = new AccountData();
        
        Map<String, Object> baseObject = (Map<String, Object>) customerMap.get('BaseObject');
        accountData.customerId = (String) baseObject.get('CustomerID');
        accountData.name = (String) baseObject.get('Name');
        accountData.outOfBusinessDate = (String) baseObject.get('OutOfBusinessDate');
        
        List<Object> phoneList = (List<Object>) customerMap.get('Phone');
        if (phoneList != null && !phoneList.isEmpty()) {
            Map<String, Object> phoneObj = (Map<String, Object>) phoneList.get(0);
            accountData.phone = (String) phoneObj.get('PhoneNumber');
        }
        
        List<Object> sources = (List<Object>) customerMap.get('Sources');
        if (sources != null && !sources.isEmpty()) {
            for (Object s : sources) {
                SourceData sourceData = new SourceData();
                Map<String, Object> source = (Map<String, Object>) s;
                
                sourceData.sourceSystem = (String) source.get('SourceSystem');
                sourceData.sourceSystemId = (String) source.get('SourceSystemID');
                accountData.sources.add(sourceData);
            }
        }
        return accountData;
    }

    private static PersonData parsePersonData(Map<String, Object> personMap) {
        PersonData personData = new PersonData();
        
        Map<String, Object> baseObject = (Map<String, Object>) personMap.get('BaseObject');
        personData.personId = (String) baseObject.get('PersonID');
        personData.firstName = (String) baseObject.get('FirstName');
        personData.midName = (String) baseObject.get('MidName');
        
        List<Object> relationships = (List<Object>) personMap.get('Relationship');
        if (relationships != null && !relationships.isEmpty()) {
            for (Object r : relationships) {
                RelationshipData relationshipData = new RelationshipData();
                
                Map<String, Object> relationship = (Map<String, Object>) r;
                relationshipData.customerId = (String) relationship.get('CustomerID');
                relationshipData.relationshipType = (String) relationship.get('RelationshipType');
                personData.relationships.add(relationshipData);
            }
        }
        return personData;
    }
}