/**
 * @Class Name: LoanRequestsTriggerHandler
 * @Description: Handles business logic for LoanRequest__c trigger events.
 *              Ensures clean separation of concerns and support for bulk operations.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-06
 */
public with sharing class LoanRequestsTriggerHandler {

    /**
     * @Method Name: beforeInsert
     * @Input: List<LoanRequest__c> newRecords
     * @Description: Populates default values for new LoanRequest__c records before insertion.
     */
    public void beforeInsert(List<LoanRequest__c> newRecords) {
        for (LoanRequest__c req : newRecords) {
            if (req.RequestDate__c == null) {
                req.RequestDate__c = Date.today();
            }
            if (String.isBlank(req.LoanStatus__c)) {
                req.LoanStatus__c = 'Draft';
            }
        }
    }

    /**
     * @Method Name: beforeUpdate
     * @Input: List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap
     * @Description: Prevents regression in LoanStatus__c and validates updates before saving.
     */
    public void beforeUpdate(List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap) {
        for (LoanRequest__c req : newRecords) {
            LoanRequest__c oldRec = oldMap.get(req.Id);
            if (oldRec != null && oldRec.LoanStatus__c == 'Approved' && req.LoanStatus__c == 'Draft') {
                req.LoanStatus__c = oldRec.LoanStatus__c;
            }
        }
    }

    /**
     * @Method Name: afterInsert
     * @Input: List<LoanRequest__c> newRecords
     * @Description: Creates Audit__c records for newly inserted LoanRequest__c records.
     */
    public void afterInsert(List<LoanRequest__c> newRecords) {
        List<Audit__c> audits = new List<Audit__c>();

        for (LoanRequest__c req : newRecords) {
            Audit__c a = new Audit__c();
            a.Customer__c = req.Customer__c;
            a.Loan_Request__c = req.Id;
            a.Loan_Amount__c = req.LoanAmount__c;
            a.Loan_Status__c = req.LoanStatus__c;
            a.Action__c = 'Created';
            a.ActionDate__c = DateTime.now();
            a.Description__c = 'Loan request created.';
            audits.add(a);
        }

        if (!audits.isEmpty()) {
            try {
                insert audits;
            } catch (DmlException e) {
                System.debug('afterInsert - Audit insert failed: ' + e.getMessage());
            }
        }
    }

    /**
     * @Method Name: afterUpdate
     * @Input: List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap
     * @Description: Logs status changes in Audit__c after LoanRequest__c updates.
     */
    public void afterUpdate(List<LoanRequest__c> newRecords, Map<Id, LoanRequest__c> oldMap) {
        List<Audit__c> audits = new List<Audit__c>();

        for (LoanRequest__c req : newRecords) {
            LoanRequest__c oldRec = oldMap.get(req.Id);
            if (oldRec == null) continue;

            if (req.LoanStatus__c != oldRec.LoanStatus__c) {
                Audit__c a = new Audit__c();
                a.Customer__c = req.Customer__c;
                a.Loan_Request__c = req.Id;
                a.Loan_Amount__c = req.LoanAmount__c;
                a.Loan_Status__c = req.LoanStatus__c;
                a.Action__c = 'Status Changed';
                a.ActionDate__c = DateTime.now();
                a.Description__c = 'Status changed from ' + oldRec.LoanStatus__c + ' to ' + req.LoanStatus__c;
                audits.add(a);
            }
        }

        if (!audits.isEmpty()) {
            try {
                insert audits;
            } catch (DmlException e) {
                System.debug('afterUpdate - Audit insert failed: ' + e.getMessage());
            }
        }
    }

    // Task creation and Email sending will be implemented in LoanRequestService
}
