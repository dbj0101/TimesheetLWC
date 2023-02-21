import { LightningElement, api, track } from 'lwc';

export default class StarCheckbox extends LightningElement {
    //https://salesforce.stackexchange.com/questions/346732/want-to-create-favorite-star-in-lwc
    
    
    @api name;
    @api itemChecked;
    onchange(event) {
      this.itemChecked = event.target.checked;
      this.dispatchEvent(
        new CustomEvent(
          'change',
            { detail: {
              name: this.name,
              checked: this.itemChecked
            }
          }
        )
      );
    }

    /*
    @api set checked(value) {
      console.log('starChecked checked:'+value);
      this.template.querySelectorAll('input').checked = value;
      console.log('2nd starChecked checked:'+value);
      this._checked = value;
    }
    get checked() {
      return this._checked;
    }
    @api name;
    @track _checked=true;
    onchange(event) {
      this._checked = event.target.checked;
      this.dispatchEvent(
        new CustomEvent(
          'change',
            { detail: {
              name: this.name,
              checked: this._checked
            }
          }
        )
      );
    }
    */
  }