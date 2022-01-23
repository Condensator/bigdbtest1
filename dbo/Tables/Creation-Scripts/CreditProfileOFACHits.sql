SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditProfileOFACHits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OFACHitId] [bigint] NOT NULL,
	[CreditProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditProfileOFACHits]  WITH CHECK ADD  CONSTRAINT [ECreditProfile_CreditProfileOFACHits] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditProfileOFACHits] CHECK CONSTRAINT [ECreditProfile_CreditProfileOFACHits]
GO
ALTER TABLE [dbo].[CreditProfileOFACHits]  WITH CHECK ADD  CONSTRAINT [ECreditProfileOFACHit_OFACHit] FOREIGN KEY([OFACHitId])
REFERENCES [dbo].[OFACHits] ([Id])
GO
ALTER TABLE [dbo].[CreditProfileOFACHits] CHECK CONSTRAINT [ECreditProfileOFACHit_OFACHit]
GO
