var parameters = {
  "protectedSettings": {
    "value": {}
  }
};
var propertyValue;
process.argv.forEach((val, index, array) => {
    switch (val) {
    case "-v":
      parameters = getKeyVaultSecret(array[index + 1]);
      break;
    case "-f":
      propertyValue = getValue(array[index + 1], "-f");
      parameters = extend(parameters, getParametersFromFile(propertyValue));
      break;
    default:
      if (val.startsWith('-')) {
        propertyValue = getValue(array[index + 1], val);
        parameters.protectedSettings.value[val.substring(1, val.length)] = propertyValue;
      }
  }
});

if (typeof parameters == 'object') {
  console.log(JSON.stringify(parameters));
}
else {
  console.log(parameters);
}

function getValue(value, flag) {
  if (typeof value == 'undefined' || value.startsWith('-')) {
    if (flag == '-f') {
      throw new Error("Value not specified for: ".concat(flag));
    }
    return "";
  }
  return value;
}

function getParametersFromFile(path) {
  var fs = require('fs');
  var jsonFile = fs.readFileSync(path, 'utf8');
  return JSON.parse(stripBOM(jsonFile)).parameters;
}

function getKeyVaultSecret(input) {
  var fs = require('fs');
  return JSON.parse(input).value;
}

function extend(target, param) {
  for (var prop in param) {
    target[prop] = param[prop];
  }
  return target;
}

function stripBOM(content) {
    // Remove byte order marker. This catches EF BB BF (the UTF-8 BOM)
    // because the buffer-to-string conversion in `fs.readFileSync()`
    // translates it to FEFF, the UTF-16 BOM.
    if (content.charCodeAt(0) === 0xFEFF || content.charCodeAt(0) === 0xFFFE) {
        content = content.slice(1);
    }
    return content;
}

