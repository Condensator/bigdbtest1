SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UDFLabelForPartyDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[UDF1Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UDFLabelForPartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UDFLabelForPartyDetails]  WITH CHECK ADD  CONSTRAINT [EUDFLabelForParty_UDFLabelForPartyDetails] FOREIGN KEY([UDFLabelForPartyId])
REFERENCES [dbo].[UDFLabelForParties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UDFLabelForPartyDetails] CHECK CONSTRAINT [EUDFLabelForParty_UDFLabelForPartyDetails]
GO
