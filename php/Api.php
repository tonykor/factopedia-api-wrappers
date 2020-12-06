<?php

/**
 * This class is used to communicate with factopedia.org API
 *
 * Usage example:
 *
 * $api = new Api;
 * $api->token='yourApiToken';
 * $object=$api->getObject(5, ['parents']);
 * 
 */

namespace app\components;

class Api {
    
    private $_token  = '';

    const URL      = 'api.factopedia.org';
    const PROTOCOL = 'https';
    const FORMAT   = 'json';

    /**
     * [getEndpoints endpoints]
     * @return [type] [description]
     */
    public function getEndpoints(){
        return [
            'Objects' => [
                'url'=>$this->getUrl()."/objects",
                'methods'=>['get', 'post', 'patch', 'put']
            ],
            'Properties' => [
                'url'=>$this->getUrl()."/properties",
                'methods'=>['get', 'post']
            ]
        ];
    }

    public function getUrl(){
        return self::PROTOCOL."://".$this->getToken().":@".self::URL;
    }

    public function getToken(){
        return $this->_token;
    }

    public function setToken($token){
        $this->_token=$token;
    }

    /**
     * [getObject this method returns object by id with speficied parameters]
     * @param  [int]    $id   [object id]
     * @param  array    $with [expand option of api]
     * @return [object]       [json object]
     */
    public function getObject($id, $with=[]){
        $url=$this->getEndpoints()['Objects']['url'].'/'.$id;
        $queryString='';
        if (!empty($with)){
            $queryString='expand='.implode(',', $with);
        }
        $method='get';
        return $this->request($url, $method, $queryString);
    }

    /**
     * [updateObject update object]
     * @param  [type] $id          [objectId]
     * @param  [type] $queryString [queryString]
     * @param  array  $images      [description]
     * @return [type]              [description]
     */
    public function updateObject($id, $queryString, $images=[]){
        $url=$this->getEndpoints()['Objects']['url'].'/'.$id;
        $contentType='multipart/form-data';
        /*
        if ($images){
            $contentType='multipart/form-data';
        }
        */
        return $this->request($url, 'post', $queryString, $images, $contentType);
    }

    public function createObject($queryString, $images=[]){
        $url=$this->getEndpoints()['Objects']['url'];
        $contentType='multipart/form-data';
        $result=$this->request($url, 'post', $queryString, $images, $contentType);
        return $result;
    }

    
    public function getObjects($params=[], $expand='suggestedProperties,parents', $exactMatch=true){
        if ($expand){
            $params['expand']=$expand;
        }
        $url=$this->getEndpoints()['Objects']['url'];
        $result=$this->request($url, 'get', http_build_query($params));
        return $result;
    }

    /**
     * [findObjects find objects by name]
     * @param  [type]  $name   [description]
     * @param  integer $parentId [description]
     * @return [type]          [description]
     */
    public function findObjects($name, $parentId=false, $lang='en', $expand='suggestedProperties,parents', $exactMatch=true){
        $params=['name'=>$name, 'lang'=>$lang];
        if ($parentId){
            $params['parentId']=$parentId;
        }
        if ($exactMatch){
            $params['exactMatch']=1;
        }
        return $this->getObjects($params, $expand, true);
    }

    private function request($url, $method, $queryString='', $files=[], $contentType=false){
        if (!$contentType){
            $contentType='application/'.self::FORMAT;
        }
        if ($method=='get'){
            $url=$url.'?'.$queryString;
        }
        $ch = curl_init($url);
        $additionalHeaders=[];
        if ($method != 'get' && $method != 'post'){
            curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
        }
        curl_setopt($ch, CURLOPT_HEADER, 0);
        curl_setopt($ch, CURLOPT_USERPWD, $this->getToken().":");
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        if ($method=='post' || $method=='put'){
            if ($method=='put'){
                curl_setopt($ch, CURLOPT_PUT, 1);
                curl_setopt($ch, CURLOPT_CUSTOMREQUEST, "PUT");
                /*
                $pieces=explode('&', $queryString);
                foreach ($pieces as $value){
                    $data=explode('=', $value);
                    $vars[urldecode($data[0])]=urldecode($data[1]);
                }
                $queryString=$vars;
                */
                $queryString=urldecode($queryString);
                $additionalHeaders[]='Content-Length: '.strlen($queryString);
            }else{
                curl_setopt($ch, CURLOPT_POST, 1);
            }
            //converting query string to array, and adding files to array
            $_queryString=[];
            $vars=explode('&', $queryString);
            foreach ($vars as $var){
                list($name, $value)=explode('=', trim($var));
                $_queryString[urldecode($name)]=urldecode($value);
            }
            if (!empty($files)){
                foreach ($files as $i=>$filepath){
                    $_queryString['Objects[imageFiles]['.$i.']']=new \CurlFile(realpath($filepath), 'image/jpg', $i.'.jpg');
                }
            }
            $queryString=$_queryString;
            unset($_queryString);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $queryString);
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, array_merge(array('Content-Type: '.$contentType), $additionalHeaders));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);
        $return = curl_exec($ch);
        //if ($method=='post'){
        //    echo $return;
        //}
        if ($return==FALSE && curl_errno($ch)) {
            //one more attempt
            sleep(2);
            $return = curl_exec($ch);
            if ($return==FALSE && curl_errno($ch)) {
                $errorMsg = curl_error($ch);
                echo 'Curl error - '.$errorMsg;
                return false;
            }
        }
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        if ($httpCode != '200' && $httpCode != '201' && $httpCode != '202' && $httpCode != '204'){
            print_r(json_decode($return, true));
            echo "User: ".$this->getToken()."\n";
            return false;
        }
        curl_close($ch);
        return json_decode($return, true);
    }

    /**
     * [getQueryString use when you want to convert object data to query string for futher api posting]
     *
     * sample data array
     *
     *          $object=[
                    'lang'        =>'en',
                    'name'        =>'name',
                    'images'      =>$imagesArray,
                    'parents'     =>[
                        'parentObjectId'=>[
                            'id'=>'parentObjectId', 
                            'name'=>'parentName'
                        ]
                    ],
                ];
     * 
     * @param  [type] $data [array of Object model]
     * @return [type]       [query string, ready for POST/PUT posting to REST api]
     */
    public function getQueryString($data){
        $usedProperties=['lang', 'name', 'description', 'aliases', 'properties', 'parents'];
        //deleting unused keys
        foreach ($data as $key => $value){
            if (!in_array($key, $usedProperties)){
                unset($data[$key]);
            }
        }
        //formating parents
        $tmpParents=[];
        if (isset($data['parents'])){
            foreach ($data['parents'] as $key => $value){
                $tmpParents[]['Objects']['id']=$value['id'];
            }
        }
        $data['parents']=$tmpParents;
        //formating properties
        $objectsPropertiesValues=[];
        if (isset($data['properties'])){
            foreach ($data['properties'] as $key => $value){
                $id=$value['name']['id'];
                $objectsPropertiesValues[$id]['ObjectsPropertiesValues']=[
                    'property_id'=>$id,
                    'type'=>$value['type'],
                    'value'=>($value['type']=='object' ? $value['value']['id'] : $value['value']),
                ];
                if (isset($value['category'])){
                    $objectsPropertiesValues[$id]['ObjectsPropertiesValues']['category_id']=$value['category']['id'];
                }
                if (isset($value['unit'])){
                    $objectsPropertiesValues[$id]['ObjectsPropertiesValues']['unit_id']=$value['unit']['id'];
                }
                if ($value['order_by'] && !is_null($value['order_by'])){
                    $objectsPropertiesValues[$id]['ObjectsPropertiesValues']['order_by']=$value['order_by'];
                }
                if ($value['link'] && !is_null($value['link'])){
                    $data['Links'][$id]['url']=$value['link'];
                }
            }
            $data['objectsPropertiesValues']=$objectsPropertiesValues;
            unset($data['properties']);
        }
        return http_build_query($data, '', "\n&");
    } 
}

?>