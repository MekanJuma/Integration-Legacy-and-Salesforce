public class Logger {
	public static void logException(Exception e) {
        // Logging logic
        // we could record the error details in custom object (Log__c)
        // we could send notification email to admin or team about the error
        String errorMsg = 'Error processing OrgPersonEvent: ' + e.getMessage() + '\n Stack Trace: ' + e.getStackTraceString();
        system.debug(errorMsg);
    }
}