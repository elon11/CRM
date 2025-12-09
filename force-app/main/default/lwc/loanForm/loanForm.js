import { LightningElement, track } from 'lwc';
import createLoanRequest from '@salesforce/apex/LoanRequestController.createLoanRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent } from 'c/pubsub';

export default class LoanForm extends LightningElement {
    @track customerName = '';
    @track loanAmount;
    @track loanStatus = '';
    @track isLoading = false;

    statusOptions = [
        { label: 'Draft', value: 'Draft' },
        { label: 'Awaiting Approval', value: 'Awaiting Approval' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    handleCustomerNameChange(event) {
        this.customerName = event.target.value;
    }

    handleLoanAmountChange(event) {
        this.loanAmount = event.target.value;
    }

    handleLoanStatusChange(event) {
        this.loanStatus = event.detail.value;
    }

    handleSave() {
        if (!this.customerName || !this.loanAmount || !this.loanStatus) {
            this.showToast('Error', 'All fields are required.', 'error');
            return;
        }

        this.isLoading = true;

        createLoanRequest({ 
            customerName: this.customerName, 
            loanAmount: parseFloat(this.loanAmount), 
            loanStatus: this.loanStatus 
        })
        .then(result => {
            this.isLoading = false;
            this.showToast('Success', 'Loan request created successfully.', 'success');

            // 🔹Saving the Id in sessionStorage to preserve the data after refresh
            window.sessionStorage.setItem('lastLoanId', result.Id);

          
            fireEvent('loanCreated', result);

            // Reset form
            this.customerName = '';
            this.loanAmount = null;
            this.loanStatus = '';
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast(
                'Error',
                error.body ? error.body.message : error.message,
                'error'
            );
        });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}
