##Usage examples

###Change object category (parent object)

```
$api = new Api();
$api->setToken(__API_TOKEN__);
$object=$api->getObject($objectId, ['children', 'parents', 'properties']);
$object['parents'][reset($object['parents'])['id']]['id']=$newParentId;
$api->updateObject($object['id'], $api->getQueryString($object));
```


###Copy properties from another objects

```
$api = new Api();
$api->setToken(__API_TOKEN__);
$toObject=$api->getObject($copyToObjectId, ['parents', 'properties']);
$fromObject=$api->getObject($copyFromObjectId, ['properties']);
$toObject['properties']=$fromObject['properties'];
$api->updateObject($copyToObjectId, $api->getQueryString($toObject));
```
