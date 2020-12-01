


# load cluster membership files

human_clus <- read.delim(file="human_out.tsv", sep="\t", header=FALSE)

mouse_clus <- read.delim(file="mouse_out.tsv", sep="\t", header=FALSE)


# get host-specific clusters

human_only <- human_clus[which(!(human_clus$V1 %in% mouse_clus$V1)),]

mouse_only <- mouse_clus[which(!(mouse_clus$V1 %in% human_clus$V1)),]

# get shared-host clusters

mouse_shared <- mouse_clus[which(mouse_clus$V1 %in% human_clus$V1),]
human_shared <- human_clus[which(human_clus$V1 %in% mouse_clus$V1),]
shared <- rbind(mouse_shared, human_shared)


# write output files

write.table(x=human_only, file="human_specific_clusters.csv", sep=",", col.names=FALSE, row.names=FALSE, quote=FALSE)
write.table(x=mouse_only, file="mouse_specific_clusters.csv", sep=",", col.names=FALSE, row.names=FALSE, quote=FALSE)
write.table(x=shared, file="shared_host_clusters.csv", sep=",", col.names=FALSE, row.names=FALSE, quote=FALSE)
