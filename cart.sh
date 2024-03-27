- name: Installing cart component
  hosts: localhost
  become: yes
  tasks:
  - name: setup npm resource
    ansible.builtin.shell: "curl -sL https://rpm.nodesource.com/setup_lts.x | bash"
  
  - name: install nodejs
    ansible.builtin.yum:
      name: nodejs
      state: installed
  - name: checkroboshop user exist or not
    ansible.builtin.command: id roboshop
    register: output # output is variable name
    ignore_errors: true
  
  - when: output.rc !=0
    name: create user roboshop
    ansible.builtin.user:
      name: roboshop

  - name: check /app directory exit or not
    ansible.builtin.stat:
      path: /app
    register: directory

  - name: print the director stats
    ansible.builtin.debug:
        msg: "output: {{directory}}"

  - when: directory.stat.exists == False
    name: create /app directory
    ansible.builtin.file:
      path: /app
      state: directory  
  
  - name: download cart artifact
    ansible.builtin.get_url:
      url: https://roboshop-builds.s3.amazonaws.com/cart.zip
      dest: /tmp

  - name: extract the artifact
    ansible.builtin.unarchive:
      src: /tmp/cart.zip
      dest: /app
      remote_src: yes
    
  - name: install dependencies
    ansible.builtin.command: npm install 
      args:
        chdir: /app
  
  - name: copy cart service
    ansible.builtin.copy:
      src: cart.service
      dest: /etc/systemd/system/cart.service
  
  - name: daemon reload
    ansible.builtin.systemd:
      daemon_relaod: true


  - name: restart cart
    ansible.builtin.service:
      name: cart
      state: restarted
      enabled: true
      