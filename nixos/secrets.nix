{inputs, ...}:

{
  age.secrets = {
    "esi-passwordfile" = {
      file = "${inputs.secrets}/esi-passwordfile.age";
    };
  };
}
