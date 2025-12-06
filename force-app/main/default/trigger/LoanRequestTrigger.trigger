/**
 * @Description: Trigger for LoanRequest__c handling before and after DML operations.
 *              Handles default values, audit logging, and high amount task creation.
 * @Created by: Elon Ifrach
 * @Created Date: 2025-12-04
 */
trigger LoanRequestTrigger on LoanRequest__c (before insert, before update, after insert, after update) {
    LoanRequestsTriggerHandler handler = new LoanRequestsTriggerHandler();

    // --- BEFORE INSERT/UPDATE ---
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    // --- AFTER INSERT/UPDATE ---
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
            // Create Tasks for high amount loans
            LoanRequestService.createHighAmountTasks(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
            // Create Tasks for high amount loans after update
            LoanRequestService.createHighAmountTasks(Trigger.new);
            // Send approval emails after update
            LoanRequestService.sendApprovalEmails(Trigger.new, Trigger.oldMap);
        }
    }
}
