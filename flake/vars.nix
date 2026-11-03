let
  sshPublicKeyMacbookProPersonal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSPuGGTECQmDPsiLzey+W+Q0DcEldwfwnbeqKD5Nspj rich@macbookpro-personal";
  sshPublicKeyPhone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+3hHH8ymCh7n6r6O5oibwrrOC21fCzeS/te5Rzv+zy u0_a564@localhost";
  sshPublicKeyUm790 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSxne+q64ORA+I1cdRqL2oTrrcJqY4Ev2PxzU1h+STt rich@um790";
in
{
  fullName = "Rich";
  userName = "rich";
  userEmail = "richard@rgill.co.uk";
  inherit
    sshPublicKeyMacbookProPersonal
    sshPublicKeyPhone
    sshPublicKeyUm790
    ;
  sshAllPublicKeys = [
    sshPublicKeyMacbookProPersonal
    sshPublicKeyPhone
    sshPublicKeyUm790
  ];
}
