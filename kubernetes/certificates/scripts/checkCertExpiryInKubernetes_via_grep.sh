#!/bin/bash
for TYPE in "$@";do
  echo ">>>>>> CHECKING TYPE: $TYPE <<<<<<";
  for NAME in $(kubectl get "$TYPE"'s' | grep -v 'sh.helm' | grep -v NAME | awk '{print $1}');do
    echo ">>> CHECKING NAME $NAME NEXT <<<";
    TEMPFILE=$(mktemp);
    kubectl get "$TYPE" "$NAME" -o yaml > "$TEMPFILE"
    TEST_CER=$(grep '\.csr\|\.pem\|\.key\|\.cert\|\.cer\|\.crt' < "$TEMPFILE"|head -n 1|awk '{print $1}');
    if [ -z "$TEST_CER" ];then echo '' > /dev/null;else
      echo "$NAME CER";
      grep '\.csr\|\.pem\|\.key\|\.cert\|\.cer\|\.crt' < "$TEMPFILE" | while read -r LINE || [[ -n $LINE ]];do
        FN=$(echo "$LINE" | awk -F ':' '{print $1}');
        echo "FN is '$FN'";
        CT=$(echo "$LINE" | awk -F ':' '{print $2}' | awk '{print $1}');
        echo "$CT" | base64 -d | openssl x509 -noout -enddate;
      done
    fi

    TEST_P12=$(grep '\.pkcs12\|\.pfx\|\.p12' < "$TEMPFILE"|head -n 1|awk '{print $1}');
    if [ -z "$TEST_P12" ];then echo '' > /dev/null;else
      echo "$NAME P12";
      grep '\.pkcs12\|\.pfx\|\.p12' < "$TEMPFILE" | while read -r LINE || [[ -n $LINE ]];do
        FN=$(echo "$LINE" | awk -F ':' '{print $1}');
        echo "FN is '$FN'";
        CT=$(echo "$LINE" | awk -F ':' '{print $2}' | awk '{print $1}');
        echo "$CT" | base64 -d | openssl x509 -noout -enddate;
      done
    fi

    TEST_JKS=$(grep '\.jks' < "$TEMPFILE"|head -n 1|awk '{print $1}');
    if [ -z "$TEST_JKS" ];then echo '' > /dev/null;else
      echo "$NAME JKS";
      grep '\.jks' < "$TEMPFILE" | while read -r LINE || [[ -n $LINE ]];do
        FN=$(echo "$LINE" | awk -F ':' '{print $1}');
        echo "FN is '$FN'";
        CT=$(echo "$LINE" | awk -F ':' '{print $2}' | awk '{print $1}');
        TEMPFILE_JKS=$(mktemp);
        echo "$CT" | base64 -d > "$TEMPFILE_JKS";
        keytool -list -v -keystore "$TEMPFILE_JKS" -storepass 'zaVD!jNp#Vf8zUU#' | grep "Valid from:";
        rm "$TEMPFILE_JKS";
      done
    fi

    rm "$TEMPFILE";
    echo "";
    echo "";
  done
  echo "";
  echo "";
  echo "";
done

