let
  sshPublicKeyPersonal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIASgK9NpwI8oA8cYyWdvwjrz2dTN1C5uSSqOjOnkxzEr";
  sshPublicKeyPhone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILznqOJBKWuIYDCIn2pePrUkzHHGydA1R5QlGmYtIai8 u0_a559@localhost";
  sshPublicKeyWork = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYgMHFX6iZGRl+UGb0lS53/JhORzSc68MB1n6/1NlGF rich@macbookair-work";
  sshPublicKeyUm790 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKSxne+q64ORA+I1cdRqL2oTrrcJqY4Ev2PxzU1h+STt rich@um790";
in
{
  fullName = "Rich";
  userName = "rich";
  userEmail = "richard@rgill.co.uk";
  inherit sshPublicKeyPersonal sshPublicKeyPhone sshPublicKeyWork sshPublicKeyUm790;
  sshAllPublicKeys = [
    sshPublicKeyPersonal
    sshPublicKeyPhone
    sshPublicKeyWork
    sshPublicKeyUm790
  ];
}
