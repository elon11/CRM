/**
 * @Class Name: LoanRequestsTriggerHandler
 * @Author: Elon Ifarch
 * @Created Date: 2025-12-04
 * @Description:
 *  This class contains the business logic for handling trigger events
 *  on the LoanRequest__c object. It performs the following actions:
 *
 *    1. Creates a high-priority Task assigned to a manager when the
 *       loan amount exceeds 250,000.
 *
 *    2. Sends an email notification to the customer when the loan status
 *       changes to "Approved".
 *
 *    3. Inserts an Audit__c record whenever the loan status is changed.
 *
 *  The class supports bulk operations and is intended to be called
 *  directly from a trigger.
 */
public class LoanRequestsTriggerHandler {

    /**
     * @Method Name: handleTrigger
     * @Input:
     *    newRecords - List<LoanRequest__c> : New LoanRequest records (Trigger.new)
     *    oldMap     - Map<Id, LoanRequest__c> : Old versions of the records (Trigger.oldMap)
     *
     * @Description:
     *  Main processing method for LoanRequest__c trigger events.
     *
     *  For each LoanRequest record:
     *
     *    1. **Manager Task Creation**
     *       - If LoanAmount__c > 250,000: creates a high-priority Task linked
     *         to the LoanRequest record.
     *
     *    2. **Approval Email Notification**
     *       - If the status changed to "Approved": sends a notification email
     *         to the customer.
     *
     *    3. **Audit Logging**
     *       - If the status changed: inserts an Audit__c entry documenting
     *         the status transition.
     *
     *  After processing all records, bulk DML operations are executed for:
     *  Task insert, email send, and Audit__c insert.
     *
     * @Created by: Elon Ifarch
     * @Created Date: 2025-12-04
     */
    public static void handleTrigger(List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap) {

        List<Task> tasksToCreate = new List<Task>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Audit__c> auditsToInsert = new List<Audit__c>();

        for (LoanRequest__c lr : newRecords) {

            // 1. Manager Task creation for high loan amount
            if (lr.LoanAmount__c > 250000) {
                Task t = new Task(
                    Subject = 'High Loan Alert',
                    Description = 'Loan request over 250,000 for ' + lr.Customer__r.Name,
                    OwnerId = 'INSERT_MANAGER_USER_ID', // Replace with actual manager Id
                    WhatId = lr.Id,
                    Status = 'Not Started',
                    Priority = 'High'
                );
                tasksToCreate.add(t);
            }

            // 2. Send approval email when status becomes "Approved"
            if (oldMap != null && oldMap.containsKey(lr.Id)) {
                LoanRequest__c oldRecord = oldMap.get(lr.Id);
                if (lr.LoanStatus__c == 'Approved' && oldRecord.LoanStatus__c != 'Approved') {

                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { lr.Customer__r.Email });
                    email.setSubject('Loan Request Approved');
                    email.setPlainTextBody('Your loan request has been approved.');
                    
                    emailsToSend.add(email);
                }
            }

            // 3. Audit record creation when status changes
            if (oldMap != null && oldMap.containsKey(lr.Id)) {
                LoanRequest__c oldRecord = oldMap.get(lr.Id);
                if (lr.LoanStatus__c != oldRecord.LoanStatus__c) {

                    Audit__c audit = new Audit__c(
                        LoanRequest__c = lr.Id,
                        CustomerName__c = lr.Customer__r.Name,
                        ChangedStatus__c = lr.LoanStatus__c
                    );

                    auditsToInsert.add(audit);
                }
            }
        }

        // Bulk DML
        if (!tasksToCreate.isEmpty()) insert tasksToCreate;
        if (!emailsToSend.isEmpty()) Messaging.sendEmail(emailsToSend);
        if (!auditsToInsert.isEmpty()) insert auditsToInsert;
    }
}
