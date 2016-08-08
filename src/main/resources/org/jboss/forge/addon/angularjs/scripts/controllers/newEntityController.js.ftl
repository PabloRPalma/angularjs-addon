<#assign
    angularApp = "${projectId}"
    angularController = "New${entityName}Controller"
    angularResource = "${entityName}Resource"
    model = "$scope.${entityName?uncap_first}"
    entityText = "${entityName?uncap_first}"
    entityRoute = "/${pluralizedEntityName}"
>
<#--An assignment expression that 'captures' all the related resources -->
<#assign relatedResources>
<#list properties as property>
<#if (property["many-to-one"]!) == "true" || (property["one-to-one"]!) == "true" || (property["n-to-many"]!) == "true">
, ${property.simpleType}Resource<#t>
</#if>
</#list>
</#assign>

angular.module('${angularApp}').controller('${angularController}', function ($scope, $location, locationParser, flash, ${angularResource} ${relatedResources}) {
    $scope.disabled = false;
    $scope.$location = $location;
    ${model} = ${model} || {};
    
    <#list properties as property>
    <#if (property["many-to-one"]!) == "true" || (property["one-to-one"]!) == "true">
    <#assign
        relatedResource="${property.simpleType}Resource"
        relatedCollection="$scope.${property.identifier}List"
        modelProperty = "${model}.${property.name}"
        selectCollection="$scope.${property.identifier}SelectionList"
        selectedItem="${property.identifier}Selection"
        reverseId = property["reverse-primary-key"]!>
    ${relatedCollection} = ${relatedResource}.queryAll(function(items){
        ${selectCollection} = $.map(items, function(item) {
            return ( {
                value : item.${reverseId},
                text : item.${property.optionLabel}
            });
        });
    });
    $scope.$watch("${selectedItem}", function(selection) {
        if ( typeof selection != 'undefined') {
            ${modelProperty} = {};
            ${modelProperty}.${reverseId} = selection.value;
        }
    });
    
    <#elseif (property["n-to-many"]!) == "true">
    <#assign
        relatedResource = "${property.simpleType}Resource"
        relatedCollection = "$scope.${property.identifier}List"
        modelProperty = "${model}.${property.name}"
        selectCollection="$scope.${property.identifier}SelectionList"
        selectedItem="${property.identifier}Selection"
        reverseId = property["reverse-primary-key"]!>
    ${relatedCollection} = ${relatedResource}.queryAll(function(items){
        ${selectCollection} = $.map(items, function(item) {
            return ( {
                value : item.${reverseId},
                text : item.${property.optionLabel}
            });
        });
    });
    $scope.$watch("${selectedItem}", function(selection) {
        if (typeof selection != 'undefined') {
            ${modelProperty} = [];
            $.each(selection, function(idx,selectedItem) {
                var collectionItem = {};
                collectionItem.${reverseId} = selectedItem.value;
                ${modelProperty}.push(collectionItem);
            });
        }
    });

    <#elseif property.type == "boolean">
        <#assign
        lookupCollection = "$scope.${property.identifier}List">
    ${lookupCollection} = [
        "true",
        "false"
    ];

    <#elseif property["lookup"]??>
    <#assign
        lookupCollection ="$scope.${property.identifier}List">
    ${lookupCollection} = [
    <#list property["lookup"]?split(",") as option>
        "${option}"<#if option_has_next>,</#if>
    </#list>
    ];
    
    </#if>
    </#list>

    $scope.save = function() {
        var successCallback = function(data,responseHeaders){
            var id = locationParser(responseHeaders);
            flash.setMessage({'type':'success','text':'The ${entityText} was created successfully.'});
            $location.path('${entityRoute}');
        };
        var errorCallback = function(response) {
            if(response && response.data) {
                flash.setMessage({'type': 'error', 'text': response.data.message || response.data}, true);
            } else {
                flash.setMessage({'type': 'error', 'text': 'Something broke. Retry, or cancel and start afresh.'}, true);
            }
        };
        ${angularResource}.save(${model}, successCallback, errorCallback);
    };
    
    $scope.cancel = function() {
        $location.path("${entityRoute}");
    };
});