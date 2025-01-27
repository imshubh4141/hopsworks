/*
 * Changes to this file committed after and not including commit-id: ccc0d2c5f9a5ac661e60e6eaf138de7889928b8b
 * are released under the following license:
 *
 * This file is part of Hopsworks
 * Copyright (C) 2018, Logical Clocks AB. All rights reserved
 *
 * Hopsworks is free software: you can redistribute it and/or modify it under the terms of
 * the GNU Affero General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Hopsworks is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 *
 * Changes to this file committed before and including commit-id: ccc0d2c5f9a5ac661e60e6eaf138de7889928b8b
 * are released under the following license:
 *
 * Copyright (C) 2013 - 2018, Logical Clocks AB and RISE SICS AB. All rights reserved
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 * persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS  OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR  OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package io.hops.hopsworks.persistence.entity.tensorflow;

import io.hops.hopsworks.persistence.entity.jupyter.JupyterSettings;
import io.hops.hopsworks.persistence.entity.project.Project;
import io.hops.hopsworks.persistence.entity.user.Users;


import javax.persistence.Entity;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.persistence.EmbeddedId;
import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.JoinColumn;
import javax.persistence.Temporal;
import javax.persistence.ManyToOne;
import javax.persistence.TemporalType;


import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import javax.xml.bind.annotation.XmlRootElement;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "tensorboard", catalog = "hopsworks", schema = "")
@XmlRootElement
@NamedQueries({
        @NamedQuery(name = "TensorBoard.findAll", query = "SELECT t FROM TensorBoard t")
        , @NamedQuery(name = "TensorBoard.findByProjectId", query = "SELECT t FROM TensorBoard t WHERE " +
        "t.tensorBoardPK.projectId = :projectId")
        , @NamedQuery(name = "TensorBoard.findByUserId", query = "SELECT t FROM TensorBoard t WHERE " +
        "t.tensorBoardPK.userId = :userId")
        , @NamedQuery(name = "TensorBoard.findByUserEmail", query = "SELECT t FROM TensorBoard t WHERE " +
        "t.users.email = :email")
        , @NamedQuery(name = "TensorBoard.findByMlId", query = "SELECT t FROM TensorBoard t WHERE " +
        "t.mlId = :mlId")
        , @NamedQuery(name = "TensorBoard.findByProjectAndUser", query = "SELECT t FROM TensorBoard t WHERE " +
        "t.tensorBoardPK.projectId = :projectId AND t.tensorBoardPK.userId = :userId")})
public class TensorBoard implements Serializable {

  private static final long serialVersionUID = 1L;
  @EmbeddedId
  private TensorBoardPK tensorBoardPK;

  @Column(name = "cid")
  private String cid;

  @Size(min = 1,
          max = 100)
  @Column(name = "endpoint")
  private String endpoint;

  @Size(min = 1,
          max = 100)
  @Column(name = "ml_id")
  private String mlId;

  @Basic(optional = false)
  @NotNull
  @Column(name = "last_accessed")
  @Temporal(TemporalType.TIMESTAMP)
  private Date lastAccessed;

  @Size(min = 1,
          max = 10000)
  @Column(name = "hdfs_logdir")
  private String hdfsLogdir;

  @Basic(optional = false)
  @NotNull
  @Size(min = 1,
          max = 255)
  @Column(name = "secret")
  private String secret;

  @JoinColumn(name = "project_id",
      referencedColumnName = "id",
      insertable = false,
      updatable = false)
  @ManyToOne(optional = false)
  private Project project;

  @JoinColumn(name = "user_id",
      referencedColumnName = "uid",
      insertable = false,
      updatable = false)
  @ManyToOne(optional = false)
  private Users users;


  public TensorBoard() {
  }

  public TensorBoard(TensorBoardPK tensorBoardPK) {
    this.setTensorBoardPK(tensorBoardPK);
  }

  public TensorBoard(TensorBoardPK tensorBoardPK, String cid, String endpoint, String mlId,
                           Date lastAccessed, String hdfsLogdir, String secret) {
    this.setTensorBoardPK(tensorBoardPK);
    this.setCid(cid);
    this.setEndpoint(endpoint);
    this.setMlId(mlId);
    this.setLastAccessed(lastAccessed);
    this.setHdfsLogdir(hdfsLogdir);
    this.setSecret(secret);
  }

  public TensorBoardPK getTensorBoardPK() {
    return tensorBoardPK;
  }

  public void setTensorBoardPK(TensorBoardPK tensorBoardPK) {
    this.tensorBoardPK = tensorBoardPK;
  }

  public String getCid() {
    return cid;
  }

  public void setCid(String cid) {
    this.cid = cid;
  }

  public String getEndpoint() {
    return endpoint;
  }

  public void setEndpoint(String endpoint) {
    this.endpoint = endpoint;
  }

  public Date getLastAccessed() {
    return lastAccessed;
  }

  public void setLastAccessed(Date lastAccessed) {
    this.lastAccessed = lastAccessed;
  }

  public String getHdfsLogdir() {
    return hdfsLogdir;
  }

  public void setHdfsLogdir(String hdfsLogdir) {
    this.hdfsLogdir = hdfsLogdir;
  }

  public String getMlId() {
    return mlId;
  }

  public void setMlId(String mlId) {
    this.mlId = mlId;
  }

  public String getSecret() {
    return secret;
  }

  public void setSecret(String secret) {
    this.secret = secret;
  }

  public Project getProject() {
    return project;
  }

  public void setProject(Project project) {
    this.project = project;
  }

  public Users getUsers() {
    return users;
  }

  public void setUsers(Users user) {
    this.users = user;
  }

  @Override
  public int hashCode() {
    int hash = 0;
    hash += (tensorBoardPK != null ? tensorBoardPK.hashCode() : 0);
    return hash;
  }

  @Override
  public boolean equals(Object object) {
    // TODO: Warning - this method won't work in the case the id fields are not set
    if (!(object instanceof JupyterSettings)) {
      return false;
    }
    TensorBoard other = (TensorBoard) object;
    if ((this.tensorBoardPK == null && other.tensorBoardPK != null) || (this.tensorBoardPK != null
        && !this.tensorBoardPK.equals(other.tensorBoardPK))) {
      return false;
    }
    return true;
  }

  @Override
  public String toString() {
    return "io.hops.hopsworks.persistence.entity.tensorflow.TensorBoard[ tensorBoardPK="
        + tensorBoardPK + " ]";
  }
}
