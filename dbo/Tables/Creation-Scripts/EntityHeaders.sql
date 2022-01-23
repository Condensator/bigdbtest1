SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EntityHeaders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[EntityNaturalId] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntitySummary] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AccessScope] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AccessScopeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EntityHeaders]  WITH CHECK ADD  CONSTRAINT [EEntityHeader_EntityType] FOREIGN KEY([EntityTypeId])
REFERENCES [dbo].[EntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[EntityHeaders] CHECK CONSTRAINT [EEntityHeader_EntityType]
GO
