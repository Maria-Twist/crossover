/**
 * Created by Pavel Kovalevsky on 11/12/2020.
 */

public with sharing class SpecialistsTableController {

    @AuraEnabled
    public static List<SpecialistsWrapper> getInitialInfo(Id recId) {
        Patient_Referral__c currentRec = [
            SELECT Patient__r.MailingLatitude, Patient__r.MailingLongitude
            FROM Patient_Referral__c
            WHERE Id = :recId
        ];

        Datetime currentDate = System.now().addDays(-730);

        Map<Id, Specialist__c> specMap = new Map<Id, Specialist__c>([
            SELECT Name, Specialty__c, Accepted_Insurance__c, Profile_URL__c, Lead__r.Latitude, Lead__r.Longitude, Group_Location__r.Name,
                    Location__Latitude__s, Location__Longitude__s, City__c, Group_Location__c,
                    (SELECT Id FROM Patient_Referrals__r WHERE CreatedDate > :currentDate)
            FROM Specialist__c
            ORDER BY Name
            LIMIT 10
        ]);

        List<Specialty__c> specialities = [
            SELECT Specialist__c, Name, Cost__c, Quality_Score__c, XO_Internal_Rating__c, XO_Provider_Rating__c, HCPCS__c, HCPS_Description__c
            FROM Specialty__c
            WHERE Specialist__c IN :specMap.keySet()
            ORDER BY Name
        ];

        Map<Id, List<Specialty__c>> specSpecsMap = new Map<Id, List<Specialty__c>>();
        for (Specialty__c s : specialities) {
            if (specSpecsMap.get(s.Specialist__c) == null) {
                specSpecsMap.put(s.Specialist__c, new List<Specialty__c>());
            }
            specSpecsMap.get(s.Specialist__c).add(s);
        }

        List<SpecialistsWrapper> wrapList = new List<SpecialistsWrapper>();
        for (Id sId : specMap.keySet()) {
            SpecialistsWrapper wrap = new SpecialistsWrapper();
            wrap.specId = specMap.get(sId).Id;
            wrap.specialistName = specMap.get(sId).Name + ' (' + String.valueOf(specMap.get(sId).Patient_Referrals__r.size()) + ')';
            wrap.groupName = specMap.get(sId).Group_Location__r.Name;
            wrap.groupId = specMap.get(sId).Group_Location__c;
            wrap.primarySpec = specMap.get(sId).Specialty__c;
            wrap.insurance = specMap.get(sId).Accepted_Insurance__c;
            wrap.profileUrl = specMap.get(sId).Profile_URL__c;
            wrap.cost = 0;
            wrap.quantity = 0;
            wrap.city = specMap.get(sId).City__c;
            wrap.hcpcsCodes = '';
            wrap.hcpcsDescs = '';
            wrap.otherSpecs = '';
            if (specSpecsMap.get(sId) != null) {
                Decimal averageCost = 0;
                Decimal averageQuantity = 0;
                Decimal averageInternal = 0;
                Decimal averageProvider = 0;
                for (Specialty__c spec : specSpecsMap.get(sId)) {
                    wrap.otherSpecs += spec.Name + ', ';
                    if (String.isNotBlank(spec.HCPCS__c)) {
                        wrap.hcpcsCodes += spec.HCPCS__c + ', ';
                        wrap.hcpcsDescs += spec.Name + ' - ' + spec.HCPS_Description__c + ', ';
                    }
                    if (spec.Cost__c == null) {
                        spec.Cost__c = 0;
                    }
                    averageCost += spec.Cost__c;
                    if (String.isNotBlank(spec.Quality_Score__c)) {
                        averageQuantity += Decimal.valueOf(spec.Quality_Score__c);
                    }
                    if (String.isNotBlank(spec.XO_Internal_Rating__c)) {
                        averageInternal += Decimal.valueOf(spec.XO_Internal_Rating__c);
                    }
                    if (String.isNotBlank(spec.XO_Provider_Rating__c)) {
                        averageProvider += Decimal.valueOf(spec.XO_Provider_Rating__c);
                    }
                }
                wrap.cost = (averageCost / specSpecsMap.get(sId).size()).setScale(2);
                wrap.quantity = (averageQuantity / specSpecsMap.get(sId).size()).round();
                wrap.otherSpecs = wrap.otherSpecs.removeEnd(', ');
                wrap.hcpcsCodes = wrap.hcpcsCodes.removeEnd(', ');
                wrap.hcpcsDescs = wrap.hcpcsDescs.removeEnd(', ');
                if (String.isNotBlank(wrap.hcpcsCodes)) {
                    wrap.firstCode = Decimal.valueOf(wrap.hcpcsCodes.substringBefore(','));
                } else {
                    wrap.firstCode = 0;
                }
//                wrap.internalRating = (averageInternal / specSpecsMap.get(sId).size()).setScale(2);
//                wrap.provideRating = (averageProvider / specSpecsMap.get(sId).size()).setScale(2);
                wrap.internalRating = (averageInternal / specSpecsMap.get(sId).size()).round();
                wrap.provideRating = (averageProvider / specSpecsMap.get(sId).size()).round();
            }

            // if (currentRec.Patient__r.MailingLatitude != null && currentRec.Patient__r.MailingLongitude != null &&
            //     ((specMap.get(sId).Lead__r.Latitude != null && specMap.get(sId).Lead__r.Longitude != null) ||
            //     (specMap.get(sId).Location__latitude__s != null && specMap.get(sId).Location__longitude__s != null)))  {
            //     Location loc1 = Location.newInstance(currentRec.Patient__r.MailingLatitude, currentRec.Patient__r.MailingLongitude);
            //  Location loc1
            //     Location loc2;
            //     if (specMap.get(sId).Location__latitude__s != null) {
            //         loc2 = Location.newInstance(specMap.get(sId).Location__latitude__s, specMap.get(sId).Location__longitude__s);
            //     } else {
            //         loc2 = Location.newInstance(specMap.get(sId).Lead__r.Latitude, specMap.get(sId).Lead__r.Longitude);
            //     }
            //     wrap.dist = Decimal.valueOf(Location.getDistance(loc1, loc2, 'mi')).setScale(3);
            // }
            wrapList.add(wrap);
        }

        return wrapList;
    }

    @AuraEnabled
    public static List<SpecialistsWrapper> getFilteredRecords(Id recId, String zip, String city, String specs) {
        if (String.isBlank(zip) && String.isBlank(city) && String.isBlank(specs)) {
            List<SpecialistsWrapper> wraps = getInitialInfo(recId);
            return wraps;
        }

        List<Specialist__c> checkLocation = new List<Specialist__c>();

        Patient_Referral__c currentRec = [
                SELECT Patient__r.MailingLatitude, Patient__r.MailingLongitude
                FROM Patient_Referral__c
                WHERE Id = :recId
        ];

        Datetime currentDate = System.now().addDays(-730);

        String query = 'SELECT Name, Specialty__c, Accepted_Insurance__c, Profile_URL__c, Country__c, City__c, Street__c, Zip__c, ' +
                'Lead__r.Latitude, Lead__r.Longitude, Location__latitude__s, Location__longitude__s, Group_Location__r.Name, Group_Location__c, ' +
                '(SELECT Id FROM Patient_Referrals__r WHERE CreatedDate > :currentDate) FROM Specialist__c WHERE ';

        List<String> zips = new List<String>();
        if (String.isNotBlank(zip)) {
            zips = zip.replaceAll(' ', '').split(',');
            if (zips.size() == 1) {
                checkLocation = [
                        SELECT Location__Latitude__s, Location__Longitude__s
                        FROM Specialist__c
                        WHERE Zip__c = :zips.get(0) AND Location__Latitude__s != NULL AND Location__Longitude__s != NULL
                        LIMIT 1
                ];

                if (checkLocation.isEmpty()) {
                    query+= 'Zip__c IN: zips ';
                } else {
                    Double lat = checkLocation.get(0).Location__Latitude__s;
                    Double lon = checkLocation.get(0).Location__Longitude__s;
                    query+= '(DISTANCE(Location__c, GEOLOCATION(' + lat + ','+ lon + '), \'mi\') < 20 OR Zip__c IN: zips) ';
                }
            } else {
                query+= 'Zip__c IN: zips ';
            }
        }

        List<String> cities = new List<String>();
        if (String.isNotBlank(city)) {
            List<String> citiesTemp = city.split(',');
            for (String s : citiesTemp) {
                cities.add(s.trim());
            }
            if (String.isNotBlank(zip)) {
                query+= 'AND ';
            }

            if (cities.size() == 1) {
                checkLocation = [
                        SELECT Location__Latitude__s, Location__Longitude__s
                        FROM Specialist__c
                        WHERE City__c = :cities.get(0) AND Location__Latitude__s != NULL AND Location__Longitude__s != NULL
                        LIMIT 1
                ];

                if (checkLocation.isEmpty()) {
                    query+= 'City__c IN: cities ';
                } else {
                    Double lat = checkLocation.get(0).Location__Latitude__s;
                    Double lon = checkLocation.get(0).Location__Longitude__s;
                    query+= '(DISTANCE(Location__c, GEOLOCATION(' + lat + ','+ lon + '), \'mi\') < 20 OR City__c IN: cities) ';
                }
            } else {
                query+= 'City__c IN: cities ';
            }
        }
        List<Specialist__c> relatedByOthers = new List<Specialist__c>();
        if (String.isNotBlank(specs)) {
            if (String.isNotBlank(zip) || String.isNotBlank(city)) {
                query+= 'AND ';
            }
            List<String> specsList = new List<String>();
            List<String> specsListTemp = specs.split(',');
            if (!specsListTemp.isEmpty()) {
                query += '(';
            }
            for (String s : specsListTemp) {
                //specsList.add(s.trim());
                query += 'Specialty__c LIKE \'%' + s.trim()  + '%\' OR ';
            }
            query = query.removeEnd('OR ');
            if (!specsListTemp.isEmpty()) {
                query += ')';
            }
            //query+= 'Specialty__c IN: specsList ';
            String childSpecQuery = 'SELECT Specialist__c FROM Specialty__c WHERE ';
            if (!specsListTemp.isEmpty()) {
                childSpecQuery += '(';
            }
            for (String s : specsListTemp) {
                //specsList.add(s.trim());
                childSpecQuery += 'Name LIKE \'%' + s.trim()  + '%\' OR ';
            }
            childSpecQuery = childSpecQuery.removeEnd('OR ');
            if (!specsListTemp.isEmpty()) {
                childSpecQuery += ')';
            }
            childSpecQuery += ' ORDER BY Name';
            System.debug('---childSpecQuery ' + childSpecQuery);
            List<Specialty__c> childSpecialities = Database.query(childSpecQuery);
//            List<Specialty__c> childSpecialities = [
//                    SELECT Specialist__c
//                    FROM Specialty__c
//                    WHERE Name IN :specsList
//                    ORDER BY Name
//            ];
            Set<Id> sIds = new Set<Id>();
            for (Specialty__c sp : childSpecialities) {
                sIds.add(sp.Specialist__c);
            }

            String childQuery = 'SELECT Name, Specialty__c, Accepted_Insurance__c, Profile_URL__c, Country__c, City__c, Street__c, Zip__c, ' +
                    'Lead__r.Latitude, Lead__r.Longitude, Location__latitude__s, Location__longitude__s, Group_Location__r.Name, Group_Location__c, ' +
                    '(SELECT Id FROM Patient_Referrals__r WHERE CreatedDate > :currentDate) ' +
                    'FROM Specialist__c WHERE Id IN :sIds ';
            if (String.isNotBlank(zip)) {
                zips = zip.replaceAll(' ', '').split(',');
                if (zips.size() == 1) {
                    checkLocation = [
                            SELECT Location__Latitude__s, Location__Longitude__s
                            FROM Specialist__c
                            WHERE Zip__c = :zips.get(0) AND Location__Latitude__s != NULL AND Location__Longitude__s != NULL
                            LIMIT 1
                    ];

                    if (checkLocation.isEmpty()) {
                        childQuery+= 'AND Zip__c IN: zips ';
                    } else {
                        Double lat = checkLocation.get(0).Location__Latitude__s;
                        Double lon = checkLocation.get(0).Location__Longitude__s;
                        childQuery+= 'AND (DISTANCE(Location__c, GEOLOCATION(' + lat + ','+ lon + '), \'mi\') < 20 OR Zip__c IN: zips) ';
                    }
                } else {
                    childQuery+= 'AND Zip__c IN: zips ';
                }
            }

            if (String.isNotBlank(city)) {
                if (cities.size() == 1) {
                    checkLocation = [
                            SELECT Location__Latitude__s, Location__Longitude__s
                            FROM Specialist__c
                            WHERE City__c = :cities.get(0) AND Location__Latitude__s != NULL AND Location__Longitude__s != NULL
                            LIMIT 1
                    ];

                    if (checkLocation.isEmpty()) {
                        childQuery+= 'AND City__c IN: cities ';
                    } else {
                        Double lat = checkLocation.get(0).Location__Latitude__s;
                        Double lon = checkLocation.get(0).Location__Longitude__s;
                        childQuery+= 'AND (DISTANCE(Location__c, GEOLOCATION(' + lat + ','+ lon + '), \'mi\') < 20 OR City__c IN: cities) ';
                    }
                } else {
                    childQuery+= 'AND City__c IN: cities ';
                }
            }
            childQuery+= 'ORDER BY Name';
            System.debug('---childQuery ' + childQuery);
            relatedByOthers = Database.query(childQuery);
        }
        query+= 'ORDER BY Name';
        System.debug('---query' + query);
        List<Specialist__c> specRecords = Database.query(query);
        if (!relatedByOthers.isEmpty()) {
            specRecords.addAll(relatedByOthers);
            specRecords = [
                    SELECT Name, Specialty__c, Accepted_Insurance__c, Profile_URL__c, Country__c, City__c, Street__c, Zip__c,
                            Lead__r.Latitude, Lead__r.Longitude, Location__Latitude__s, Location__Longitude__s, Group_Location__r.Name, Group_Location__c,
                            (SELECT Id FROM Patient_Referrals__r WHERE CreatedDate > :currentDate)
                    FROM Specialist__c
                    WHERE Id IN :specRecords
                    ORDER BY Name
            ];

            System.debug('specRecords ==========================');
            System.debug(specRecords);
        }

        if (specRecords.isEmpty()) {
            return new List<SpecialistsWrapper>();
        }

        Map<Id, Specialist__c> specMap = new Map<Id, Specialist__c>();
        for (Specialist__c s : specRecords) {
            specMap.put(s.Id, s);
        }

        List<Specialty__c> specialities = [
                SELECT Specialist__c, Name, Cost__c, Quality_Score__c, XO_Internal_Rating__c, XO_Provider_Rating__c, HCPCS__c, HCPS_Description__c
                FROM Specialty__c
                WHERE Specialist__c IN :specMap.keySet()
                ORDER BY Name
        ];

        Map<Id, List<Specialty__c>> specSpecsMap = new Map<Id, List<Specialty__c>>();
        for (Specialty__c s : specialities) {
            if (specSpecsMap.get(s.Specialist__c) == null) {
                specSpecsMap.put(s.Specialist__c, new List<Specialty__c>());
            }
            specSpecsMap.get(s.Specialist__c).add(s);
        }

        List<SpecialistsWrapper> wrapList = new List<SpecialistsWrapper>();
        for (Id sId : specMap.keySet()) {
            SpecialistsWrapper wrap = new SpecialistsWrapper();
            wrap.specId = specMap.get(sId).Id;
            wrap.specialistName = specMap.get(sId).Name + ' (' + String.valueOf(specMap.get(sId).Patient_Referrals__r.size()) + ')';
            wrap.groupName = specMap.get(sId).Group_Location__r.Name;
            wrap.groupId = specMap.get(sId).Group_Location__c;
            wrap.primarySpec = specMap.get(sId).Specialty__c;
            wrap.insurance = specMap.get(sId).Accepted_Insurance__c;
            wrap.profileUrl = specMap.get(sId).Profile_URL__c;
            wrap.cost = 0;
            wrap.quantity = 0;
            wrap.city = specMap.get(sId).City__c;
            wrap.hcpcsCodes = '';
            wrap.hcpcsDescs = '';
            wrap.otherSpecs = '';

            if (specSpecsMap.get(sId) != null) {
                Decimal averageCost = 0;
                Decimal averageQuantity = 0;
                Decimal averageInternal = 0;
                Decimal averageProvider = 0;
                for (Specialty__c spec : specSpecsMap.get(sId)) {
                    wrap.otherSpecs += spec.Name + ', ';
                    if (String.isNotBlank(spec.HCPCS__c)) {
                        wrap.hcpcsCodes += spec.HCPCS__c + ', ';
                        wrap.hcpcsDescs += spec.Name + ' - ' + spec.HCPS_Description__c + ', ';
                    }
                    if (spec.Cost__c == null) {
                        spec.Cost__c = 0;
                    }
                    averageCost += spec.Cost__c;
                    if (String.isNotBlank(spec.Quality_Score__c)) {
                        averageQuantity += Decimal.valueOf(spec.Quality_Score__c);
                    }
                    if (String.isNotBlank(spec.XO_Internal_Rating__c)) {
                        averageInternal += Decimal.valueOf(spec.XO_Internal_Rating__c);
                    }
                    if (String.isNotBlank(spec.XO_Provider_Rating__c)) {
                        averageProvider += Decimal.valueOf(spec.XO_Provider_Rating__c);
                    }
                }
                wrap.cost = (averageCost / specSpecsMap.get(sId).size()).setScale(2);
                wrap.groupId = specMap.get(sId).Group_Location__c;
                wrap.quantity = (averageQuantity / specSpecsMap.get(sId).size()).round();
                wrap.otherSpecs = wrap.otherSpecs.removeEnd(', ');
                wrap.hcpcsCodes = wrap.hcpcsCodes.removeEnd(', ');
                wrap.hcpcsDescs = wrap.hcpcsDescs.removeEnd(', ');
                if (String.isNotBlank(wrap.hcpcsCodes)) {
                    wrap.firstCode = Decimal.valueOf(wrap.hcpcsCodes.substringBefore(','));
                } else {
                    wrap.firstCode = 0;
                }
//                wrap.internalRating = (averageInternal / specSpecsMap.get(sId).size()).setScale(2);
//                wrap.provideRating = (averageProvider / specSpecsMap.get(sId).size()).setScale(2);
                wrap.internalRating = (averageInternal / specSpecsMap.get(sId).size()).round();
                wrap.provideRating = (averageProvider / specSpecsMap.get(sId).size()).round();
            }

            if (!checkLocation.isEmpty() &&
                ((specMap.get(sId).Lead__r.Latitude != null && specMap.get(sId).Lead__r.Longitude != null) ||
                (specMap.get(sId).Location__Latitude__s != null && specMap.get(sId).Location__Longitude__s != null)))  {
                //Location loc1 = Location.newInstance(currentRec.Patient__r.MailingLatitude, currentRec.Patient__r.MailingLongitude);
                Location loc1 = Location.newInstance(checkLocation.get(0).Location__Latitude__s, checkLocation.get(0).Location__Longitude__s);
                Location loc2;
                if (specMap.get(sId).Location__Latitude__s != null) {
                    loc2 = Location.newInstance(specMap.get(sId).Location__Latitude__s, specMap.get(sId).Location__Longitude__s);
                } else {
                    loc2 = Location.newInstance(specMap.get(sId).Lead__r.Latitude, specMap.get(sId).Lead__r.Longitude);
                }
                wrap.dist = Decimal.valueOf(Location.getDistance(loc1, loc2, 'mi')).setScale(3);
            }
            wrapList.add(wrap);
        }

        System.debug('wrapList');
        System.debug(wrapList);

        return wrapList;
    }
    @AuraEnabled
    public static void updatePatientReferral(Id recId, Id specId, Decimal cost, Decimal quan, Decimal internal, Decimal provider, Id groupId) {
        System.debug('groupId');
        System.debug(groupId);

        List<Patient_Referral__c> checkRef = [
            SELECT Specialist__c, Approx_Cost_of_Appointment__c, Group_or_Institution__c,
                    Online_Ratings_Average__c, XO_Internal_Rating__c, XO_Provider_Rating__c
            FROM Patient_Referral__c
            WHERE Id = :recId
        ];
        System.debug('---checkRef' + checkRef);
        System.debug('---specId' + specId);
        if (!checkRef.isEmpty()) {
            checkRef.get(0).Specialist__c = specId;
            checkRef.get(0).Approx_Cost_of_Appointment__c = cost;
            if (groupId != null) {
                checkRef.get(0).Group_or_Institution__c = groupId;
            }
            if (internal != 0) {
                checkRef.get(0).XO_Internal_Rating__c = String.valueOf(internal);
            } else {
                checkRef.get(0).XO_Internal_Rating__c = null;
            }
            if (provider != 0) {
                checkRef.get(0).XO_Provider_Rating__c = String.valueOf(provider);
            } else {
                checkRef.get(0).XO_Provider_Rating__c = null;
            }
            if (quan != 0) {
                checkRef.get(0).Online_Ratings_Average__c = String.valueOf(quan);
            } else {
                checkRef.get(0).Online_Ratings_Average__c = null;
            }
            update checkRef;
        }
    }

    public class SpecialistsWrapper {
        @AuraEnabled public Id specId {get;set;}
        @AuraEnabled public String specialistName {get;set;}
        @AuraEnabled public String groupName {get;set;}
        @AuraEnabled public String primarySpec {get;set;}
        @AuraEnabled public String otherSpecs {get;set;}
        @AuraEnabled public Decimal cost {get;set;}
        @AuraEnabled public Decimal quantity {get;set;}
        @AuraEnabled public Decimal dist {get;set;}
        @AuraEnabled public String insurance {get;set;}
        @AuraEnabled public String profileUrl {get;set;}
        @AuraEnabled public Decimal internalRating {get;set;}
        @AuraEnabled public Decimal provideRating {get;set;}
        @AuraEnabled public String hcpcsCodes {get;set;}
        @AuraEnabled public String hcpcsDescs {get;set;}
        @AuraEnabled public Decimal firstCode {get;set;}
        @AuraEnabled public String city {get;set;}
        @AuraEnabled public String groupId {get;set;}
    }

}