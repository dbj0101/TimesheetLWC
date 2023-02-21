import { LightningElement, track, api } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import PROJECT_NAME_FIELD from '@salesforce/schema/Project__c.Name';
//import PROJECT_MEMBER_ID_FIELD from '@salesforce/schema/Project_Member.Id';
import PROJECT_FAVORITE_FIELD from '@salesforce/schema/Project_Member__c.Favorite__c';
import fetchCurrentUserProjectList from '@salesforce/apex/TimeSheetComponentController.fetchCurrentUserProjectList';
import setProjectFavorite from '@salesforce/apex/TimeSheetComponentController.setProjectFavorite';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/*
const COLUMNS = [
    {
        label: 'Favorite',
        fieldName: 'favorite', //PROJECT_FAVORITE_FIELD.fieldName,
        type: 'text'
    },
    {
        label: 'Project',
        fieldName: 'projectName', //PROJECT_NAME_FIELD.fieldName,
        type: 'text'
    }
];
*/

export default class DatatableStar extends LightningElement {

    @track projectList = [];

    @api
    get projectListHasRows() {
        console.log('projectListHasRows projectList-length:'+this.projectList.length);
        console.log('projectListHasRows projectList:'+this.projectList);
        console.log('projectListHasRows projectList-length:'+this.projectList.length);
        return this.projectList.length>0;
    }

    connectedCallback() {
        this.getProjectList();
    }

    getProjectList() {
        fetchCurrentUserProjectList({ userId : USER_ID}).then(result => {
            console.log('getProjectList result:'+result);
            this.projectList = JSON.parse(result);
        }).catch( error => {
            console.error('handleChangeFavorite:'+JSON.stringify(error));
        })
    }
    
    handleChangeFavorite(event) {
        console.log('handleChangeFavorite:'+JSON.stringify(event));
        console.log('handleChangeFavorite name:'+event.detail.name);
        console.log('handleChangeFavorite checked:'+event.detail.checked);
        setProjectFavorite({ projectMemberId : event.detail.name, favorite : event.detail.checked }).then(result => {
            console.log('handleChangeFavorite setProjectFavorite result:'+result);
        }).catch( error => {
            console.error('handleChangeFavorite:'+JSON.stringify(error));
        })
    }

    /* //Tried this and it displayed nothing
    //https://www.youtube.com/watch?v=Oxf4ChjCSG4
    columns = COLUMNS;
    
    @wire(fetchCurrentUserProjectList, { userId : USER_ID })
    projects;
    */
}