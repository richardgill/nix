let
  sshPublicKeyPersonal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIASgK9NpwI8oA8cYyWdvwjrz2dTN1C5uSSqOjOnkxzEr";
  sshPublicKeyPhone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+3hHH8ymCh7n6r6O5oibwrrOC21fCzeS/te5Rzv+zy u0_a564@localhost";
  sshPublicKeyWork = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4wgoDc6WclaOwOrE9fWc0McUtZTVFglXKzKzSI9Ia1 rich@macbookair-work";
  sshPublicKeyUm790 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSxne+q64ORA+I1cdRqL2oTrrcJqY4Ev2PxzU1h+STt rich@um790";
in
{
  fullName = "Rich";
  userName = "rich";
  userEmail = "richard@rgill.co.uk";
  waylandCompositor = "niri";
  inherit sshPublicKeyPersonal sshPublicKeyPhone sshPublicKeyWork sshPublicKeyUm790;
  sshAllPublicKeys = [
    sshPublicKeyPersonal
    sshPublicKeyPhone
    sshPublicKeyWork
    sshPublicKeyUm790
  ];
}
