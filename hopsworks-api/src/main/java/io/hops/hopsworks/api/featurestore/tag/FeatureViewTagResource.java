/*
 * This file is part of Hopsworks
 * Copyright (C) 2023, Hopsworks AB. All rights reserved
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
 */
package io.hops.hopsworks.api.featurestore.tag;

import io.hops.hopsworks.common.api.ResourceRequest;
import io.hops.hopsworks.common.featurestore.featureview.FeatureViewController;
import io.hops.hopsworks.common.featurestore.metadata.AttachMetadataResult;
import io.hops.hopsworks.common.tags.TagsDTO;
import io.hops.hopsworks.exceptions.FeaturestoreException;
import io.hops.hopsworks.exceptions.FeatureStoreMetadataException;
import io.hops.hopsworks.persistence.entity.featurestore.featureview.FeatureView;
import io.hops.hopsworks.persistence.entity.featurestore.metadata.FeatureStoreTag;

import javax.ejb.EJB;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.enterprise.context.RequestScoped;
import javax.ws.rs.core.UriInfo;
import java.util.Map;
import java.util.Optional;

@RequestScoped
@TransactionAttribute(TransactionAttributeType.NEVER)
public class FeatureViewTagResource extends FeatureStoreTagResource {
  
  private FeatureView featureView;
  @EJB
  private FeatureViewController featureViewController;
  
  /**
   * Sets the feature view of the tag resource
   *
   * @param name
   * @param version
   */
  public void setFeatureView(String name, Integer version) throws FeaturestoreException {
    this.featureView = featureViewController.getByNameVersionAndFeatureStore(name, version, featureStore);
  }
  
  @Override
  protected Optional<FeatureStoreTag> getTag(String name) throws FeatureStoreMetadataException {
    return tagController.getTag(featureView, name);
  }
  
  @Override
  protected Map<String, FeatureStoreTag> getTags() {
    return tagController.getTags(featureView);
  }
  
  @Override
  protected AttachMetadataResult<FeatureStoreTag> putTag(String name, String value)
    throws FeatureStoreMetadataException, FeaturestoreException {
    return tagController.upsertTag(featureView, name, value);
  }
  
  @Override
  protected AttachMetadataResult<FeatureStoreTag> putTags(Map<String, String> tags)
    throws FeatureStoreMetadataException, FeaturestoreException {
    return tagController.upsertTags(featureView, tags);
  }
  
  @Override
  protected void deleteTag(String name) throws FeatureStoreMetadataException, FeaturestoreException {
    tagController.deleteTag(featureView, name);
  }
  
  @Override
  protected void deleteTags() throws FeaturestoreException {
    tagController.deleteTags(featureView);
  }
  
  @Override
  protected TagsDTO buildPutTags(UriInfo uriInfo, ResourceRequest request, Map<String, FeatureStoreTag> tags)
    throws FeatureStoreMetadataException {
    return tagBuilder.build(uriInfo, request, project.getId(), featureStore.getId(),
      ResourceRequest.Name.FEATUREVIEW, featureView.getId(), tags);
  }
  
  @Override
  protected TagsDTO buildGetTags(UriInfo uriInfo, ResourceRequest request, Map<String, FeatureStoreTag> tags)
    throws FeatureStoreMetadataException {
    return tagBuilder.build(uriInfo, request, project.getId(), featureStore.getId(),
      ResourceRequest.Name.FEATUREVIEW, featureView.getId(), tags);
  }
}
