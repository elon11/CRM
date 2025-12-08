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
     * @Method Name: sendApprovalEmailsToCustomer
     * @Input: List<LoanRequest__c> loanRequests, Map<Id, LoanRequest__c> oldMap
     * @Description: Sends email notifications to customers when LoanRequest__c status changes to 'Approved'.
     *              Supports bulk operations and prevents sending duplicate emails.
     *              Uses the Email__c field on the Customer__c object.
     * @Created by: Elon Ifrach
     * @Created Date: 2025-12-08
     */
    public static void sendApprovalEmails(List<LoanRequest__c> loanRequests, Map<Id, LoanRequest__c> oldMap) {
        if (loanRequests == null || loanRequests.isEmpty()) return;
        // Step 1: Collect all related Customer Ids
        Set<Id> customerIds = new Set<Id>();
        for (LoanRequest__c lr : loanRequests) {
            LoanRequest__c oldRec = oldMap.get(lr.Id);
            if (oldRec != null && lr.LoanStatus__c == 'Approved' && oldRec.LoanStatus__c != 'Approved') {
                if (lr.Customer__c != null) {
                    customerIds.add(lr.Customer__c);
                }
            }
        }
    
        if (customerIds.isEmpty()) return;
    
        // Step 2: Query Customers' email addresses
        Map<Id, Customer__c> customersMap = new Map<Id, Customer__c>(
            [SELECT Id, Name, Email__c FROM Customer__c WHERE Id IN :customerIds]
        );
    
        // Step 3: Prepare emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (LoanRequest__c lr : loanRequests) {
            LoanRequest__c oldRec = oldMap.get(lr.Id);
            if (oldRec != null && lr.LoanStatus__c == 'Approved' && oldRec.LoanStatus__c != 'Approved') {
                if (lr.Customer__c != null) {
                    Customer__c cust = customersMap.get(lr.Customer__c);
                    if (cust != null && String.isNotBlank(cust.Email__c)) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[] { cust.Email__c });
                        mail.setSubject('Your Loan Request is Approved');
                        mail.setPlainTextBody(
                            'Dear ' + cust.Name + ',\n\n' +
                            'Your loan request for amount ' + lr.LoanAmount__c + ' has been approved.\n\n' +
                            'Thank you,\nBank CRM System'
                        );
                        emails.add(mail);
                    }
                }
            }
        }
    
        // Step 4: Send emails if any
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('LoanRequestService.sendApprovalEmailsToCustomer - Email send failed: ' + e.getMessage());
            }
        }
    }

}
