/**
 * @Class Name: LoanRequestService
 * @Description: Service class for handling business logic related to LoanRequest__c,
 *              including Task creation and Email sending.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-06
 */
public with sharing class LoanRequestService {

    /**
     * @Method Name: createHighAmountTasks
     * @Input: List<LoanRequest__c> loanRequests
     * @Description: Creates Tasks for LoanRequest__c records where LoanAmount__c > 250,000.
     *              Ensures bulk operation support and assigns tasks to the bank manager.
     */
    public static void createHighAmountTasks(List<LoanRequest__c> loanRequests) {
        if (loanRequests == null || loanRequests.isEmpty()) return;

        List<Task> tasksToInsert = new List<Task>();

  
        Id managerId = '0058e000001CC0UAAW'; // elon Id

        for (LoanRequest__c req : loanRequests) {
            if (req.LoanAmount__c != null && req.LoanAmount__c > 250000) {
                Task t = new Task();
                t.Subject = 'High Loan Amount Approval Needed';
                t.OwnerId = managerId;
                t.WhatId = req.Id; // relate task to the LoanRequest__c
                t.Status = 'Not Started';
                t.Priority = 'High';
                t.Description = 'Loan request amount is over 250,000. Approval required.';
                tasksToInsert.add(t);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            try {
                insert tasksToInsert;
            } catch (DmlException e) {
                System.debug('LoanRequestService.createHighAmountTasks - Task insert failed: ' + e.getMessage());
            }
        }
    }

    /**
 * @Method Name: sendApprovalEmails
 * @Input: List<LoanRequest__c> loanRequests, Map<Id, LoanRequest__c> oldMap
 * @Description: Sends email notifications to customers when LoanRequest__c status changes to 'Approved'.
 *              Supports bulk operations and prevents sending duplicate emails.
 */
public static void sendApprovalEmails(List<LoanRequest__c> loanRequests, Map<Id, LoanRequest__c> oldMap) {
    if (loanRequests == null || loanRequests.isEmpty()) return;

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (LoanRequest__c req : loanRequests) {
        LoanRequest__c oldRec = oldMap.get(req.Id);
        if (oldRec == null) continue;

        // Check if status changed to 'Approved'
        if (req.LoanStatus__c == 'Approved' && oldRec.LoanStatus__c != 'Approved') {
            if (req.Customer__r != null && String.isNotBlank(req.Customer__r.Email__c)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { req.Customer__r.Email__c });
                mail.setSubject('Your Loan Request is Approved');
                mail.setPlainTextBody('Dear ' + req.Customer__r.Name + ',\n\n' +
                    'Your loan request for amount ' + req.LoanAmount__c + ' has been approved.\n\n' +
                    'Thank you,\nBank CRM System');
                emails.add(mail);
            }
        }
    }

    if (!emails.isEmpty()) {
        try {
            Messaging.sendEmail(emails);
        } catch (Exception e) {
            System.debug('LoanRequestService.sendApprovalEmails - Email send failed: ' + e.getMessage());
        }
    }
}

}
