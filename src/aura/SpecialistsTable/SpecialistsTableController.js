/**
 * Created by Pavel Kovalevsky on 11/12/2020.
 */
({  init : function(component, event, helper) {
        helper.doInit(component);
        console.log('---recID', component.get("v.recordId"));
    },

    sortBySpecialist : function(component, event, helper) {
        var fieldName = 'specialistName';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByPrimary : function(component, event, helper) {
        var fieldName = 'primarySpec';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByOther : function(component, event, helper) {
        var fieldName = 'otherSpecs';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByCost : function(component, event, helper) {
        var fieldName = 'cost';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByQuality : function(component, event, helper) {
        var fieldName = 'quantity';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByGroup : function(component, event, helper) {
        var fieldName = 'groupName';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByProvider : function(component, event, helper) {
        var fieldName = 'provideRating';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByInternal : function(component, event, helper) {
        var fieldName = 'internalRating';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByCity : function(component, event, helper) {
        var fieldName = 'city';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    sortByCode : function(component, event, helper) {
        var fieldName = 'firstCode';
        var sortDirection = 'asc';
        component.set("v.selectedTabsoft", fieldName);
        helper.sortData(component, fieldName, sortDirection);
    },

    searchRecords : function(component, event, helper) {
        helper.doSearch(component);
    },

    closeModal: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },

    setSpecialist: function(component, event, helper) {
        console.log('---selected', component.get("v.selectedRow"));
        console.log('---recID', component.get("v.recordId"));
        helper.saveRecord(component);
    },

    showRow: function(component, event, helper) {
        var elements = document.getElementsByClassName("trBackground");
        for (var i = 0; i<elements.length; i++) {
            elements[i].style.backgroundColor = "white";
        }
        event.currentTarget.style.backgroundColor = "rgb(236, 235, 234)";
        component.set("v.selectedRow", event.currentTarget.dataset.id);
        component.set("v.selectedCost", event.currentTarget.dataset.cost);
        component.set("v.selectedQuantity", event.currentTarget.dataset.quan);
        component.set("v.selectedProvider", event.currentTarget.dataset.prov);
        component.set("v.selectedInternal", event.currentTarget.dataset.int);
        component.set("v.selectedGroupId", event.currentTarget.dataset.group);
    }
});