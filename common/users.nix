{ users, ... }:

{
  users.extraUsers.azul = {
    isNormalUser = true;
    home = "/home/azul";
    description = "Azul";
    uid = 15626;
    extraGroups = [ "wheel" "networkmanager" "vboxusers" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGJ3Sf7iBKEpwHjDQj9d6FPYdY97MK5q82G7eioGRsC9eHVlS4Ndj/67SFB1tIXkYLCtXIai1YAH6BVI6prwoycQvb3oBCB8O8W92DbGjbqD8N5pylUPeXxL65ZI2p1ns4kshEVs4li95S3YVs1bS2veP0LP3NMFF2J1w/mPftH60MnbIY3y67sH0jN3ehF2qJBmXa1wddRVzKU9Jx4oMVl5RSpqzFjgKUI7YIz2kLM1fm39cX4HbSqA0U5+hB8nnge4GjriqGYXUg4o55F84EJcecUQaScnwTvwVD5MedyJa8bX3RcUbhT1aq2JCnJV+fjZzETZV/i01YD5AjnuJN azul@thinkpad"
    ];
  };

  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGJ3Sf7iBKEpwHjDQj9d6FPYdY97MK5q82G7eioGRsC9eHVlS4Ndj/67SFB1tIXkYLCtXIai1YAH6BVI6prwoycQvb3oBCB8O8W92DbGjbqD8N5pylUPeXxL65ZI2p1ns4kshEVs4li95S3YVs1bS2veP0LP3NMFF2J1w/mPftH60MnbIY3y67sH0jN3ehF2qJBmXa1wddRVzKU9Jx4oMVl5RSpqzFjgKUI7YIz2kLM1fm39cX4HbSqA0U5+hB8nnge4GjriqGYXUg4o55F84EJcecUQaScnwTvwVD5MedyJa8bX3RcUbhT1aq2JCnJV+fjZzETZV/i01YD5AjnuJN azul@thinkpad"
  ];
}
